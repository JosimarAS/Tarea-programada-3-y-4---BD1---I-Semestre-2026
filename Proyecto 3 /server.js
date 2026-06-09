const express = require('express');
const sql = require('mssql');
const cors = require('cors');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;

const dbConfig = {
  server: process.env.DB_SERVER || 'localhost',
  database: process.env.DB_DATABASE || 'PlanillaObreraDB',
  user: process.env.DB_USER || 'developer_proyecto3',
  password: process.env.DB_PASSWORD || 'Proyecto3_2026!',
  options: { trustServerCertificate: true, encrypt: false }
};

let pool;
async function getPool() {
  if (!pool) pool = await sql.connect(dbConfig);
  return pool;
}

function ip(req) {
  const forwarded = req.headers['x-forwarded-for'];
  return (forwarded ? forwarded.split(',')[0] : req.socket.remoteAddress || '127.0.0.1').replace('::ffff:', '');
}

function readUser(req) {
  return Number(req.body.idUsuario || req.query.idUsuario || req.headers['x-user-id'] || 0) || null;
}

async function errorMessage(code) {
  if (!code) return '';
  try {
    const p = await getPool();
    const r = await p.request().input('inCodigo', sql.Int, code).output('outResultCode', sql.Int).execute('dbo.sp_ObtenerError');
    return r.recordset?.[0]?.Descripcion || 'Error desconocido.';
  } catch {
    return 'Error desconocido.';
  }
}

async function replyByCode(res, code, payload = {}) {
  if (code === 0) return res.json({ ok: true, ...payload });
  return res.status(code === 50008 ? 500 : 400).json({ ok: false, codigo: code, mensaje: await errorMessage(code) });
}

app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(express.static(path.join(__dirname, 'public')));

app.post('/api/auth/login', async (req, res) => {
  const { username, password } = req.body;
  if (!username || !password) return res.status(400).json({ ok: false, mensaje: 'Digite usuario y contraseña.' });
  try {
    const p = await getPool();
    const r = await p.request()
      .input('inUsername', sql.VarChar(64), username)
      .input('inPassword', sql.VarChar(128), password)
      .input('inPostInIP', sql.VarChar(64), ip(req))
      .output('outIdUsuario', sql.Int)
      .output('outIdEmpleado', sql.Int)
      .output('outTipoUsuario', sql.VarChar(32))
      .output('outResultCode', sql.Int)
      .execute('dbo.sp_LoginUsuario');
    if (r.output.outResultCode !== 0) return replyByCode(res, r.output.outResultCode);
    res.json({ ok: true, usuario: { idUsuario: r.output.outIdUsuario, idEmpleado: r.output.outIdEmpleado, tipoUsuario: r.output.outTipoUsuario, username } });
  } catch (err) {
    res.status(500).json({ ok: false, mensaje: 'No se pudo conectar con SQL Server.', detalle: err.message });
  }
});

app.post('/api/auth/logout', async (req, res) => {
  const idUsuario = readUser(req);
  if (!idUsuario) return res.status(401).json({ ok: false, mensaje: 'Sesión requerida.' });
  const p = await getPool();
  const r = await p.request().input('inIdUsuario', sql.Int, idUsuario).input('inPostInIP', sql.VarChar(64), ip(req)).output('outResultCode', sql.Int).execute('dbo.sp_LogoutUsuario');
  return replyByCode(res, r.output.outResultCode, { mensaje: 'Logout registrado.' });
});

app.get('/api/puestos', async (req, res) => {
  const p = await getPool();
  const r = await p.request().output('outResultCode', sql.Int).execute('dbo.sp_ListarPuestos');
  return replyByCode(res, r.output.outResultCode, { puestos: r.recordset || [] });
});

app.get('/api/empleados', async (req, res) => {
  const idUsuario = readUser(req);
  if (!idUsuario) return res.status(401).json({ ok: false, mensaje: 'Sesión requerida.' });
  const p = await getPool();
  const r = await p.request()
    .input('inFiltro', sql.VarChar(128), String(req.query.filtro || ''))
    .input('inIdPostByUser', sql.Int, idUsuario)
    .input('inPostInIP', sql.VarChar(64), ip(req))
    .output('outResultCode', sql.Int)
    .execute('dbo.sp_ListarEmpleados');
  return replyByCode(res, r.output.outResultCode, { empleados: r.recordset || [] });
});

app.get('/api/empleados/:id', async (req, res) => {
  const p = await getPool();
  const r = await p.request().input('inIdEmpleado', sql.Int, Number(req.params.id)).output('outResultCode', sql.Int).execute('dbo.sp_ObtenerEmpleado');
  return replyByCode(res, r.output.outResultCode, { empleado: r.recordset?.[0] || null });
});

app.post('/api/empleados', async (req, res) => {
  const idUsuario = readUser(req);
  const b = req.body;
  const p = await getPool();
  const r = await p.request()
    .input('inValorDocumentoIdentidad', sql.VarChar(32), b.valorDocumentoIdentidad)
    .input('inNombre', sql.VarChar(128), b.nombre)
    .input('inIdPuesto', sql.Int, Number(b.idPuesto))
    .input('inCuentaBancaria', sql.VarChar(40), b.cuentaBancaria)
    .input('inUsername', sql.VarChar(64), b.username)
    .input('inPassword', sql.VarChar(128), b.password)
    .input('inIdTipoUsuario', sql.Int, 0)
    .input('inFechaContratacion', sql.Date, b.fechaContratacion)
    .input('inIdPostByUser', sql.Int, idUsuario)
    .input('inPostInIP', sql.VarChar(64), ip(req))
    .output('outIdEmpleado', sql.Int)
    .output('outResultCode', sql.Int)
    .execute('dbo.sp_InsertarEmpleado');
  return replyByCode(res, r.output.outResultCode, { idEmpleado: r.output.outIdEmpleado });
});

app.put('/api/empleados/:id', async (req, res) => {
  const idUsuario = readUser(req);
  const b = req.body;
  const p = await getPool();
  const r = await p.request()
    .input('inIdEmpleado', sql.Int, Number(req.params.id))
    .input('inValorDocumentoIdentidad', sql.VarChar(32), b.valorDocumentoIdentidad)
    .input('inNombre', sql.VarChar(128), b.nombre)
    .input('inIdPuesto', sql.Int, Number(b.idPuesto))
    .input('inCuentaBancaria', sql.VarChar(40), b.cuentaBancaria)
    .input('inIdPostByUser', sql.Int, idUsuario)
    .input('inPostInIP', sql.VarChar(64), ip(req))
    .output('outResultCode', sql.Int)
    .execute('dbo.sp_ActualizarEmpleado');
  return replyByCode(res, r.output.outResultCode, { mensaje: 'Empleado actualizado.' });
});

app.delete('/api/empleados/:id', async (req, res) => {
  const idUsuario = readUser(req);
  const p = await getPool();
  const r = await p.request()
    .input('inIdEmpleado', sql.Int, Number(req.params.id))
    .input('inValorDocumentoIdentidad', sql.VarChar(32), null)
    .input('inFechaSalida', sql.Date, new Date())
    .input('inIdPostByUser', sql.Int, idUsuario)
    .input('inPostInIP', sql.VarChar(64), ip(req))
    .output('outResultCode', sql.Int)
    .execute('dbo.sp_EliminarEmpleado');
  return replyByCode(res, r.output.outResultCode, { mensaje: 'Empleado eliminado.' });
});

app.post('/api/empleados/:id/impersonar', async (req, res) => {
  const idUsuario = readUser(req);
  const p = await getPool();
  const r = await p.request()
    .input('inIdEmpleado', sql.Int, Number(req.params.id))
    .input('inIdPostByUser', sql.Int, idUsuario)
    .input('inPostInIP', sql.VarChar(64), ip(req))
    .output('outResultCode', sql.Int)
    .execute('dbo.sp_ImpersonarEmpleado');
  return replyByCode(res, r.output.outResultCode, { empleado: r.recordset?.[0] });
});

app.post('/api/admin/regresar', async (req, res) => {
  const p = await getPool();
  const r = await p.request().input('inIdPostByUser', sql.Int, readUser(req)).input('inPostInIP', sql.VarChar(64), ip(req)).output('outResultCode', sql.Int).execute('dbo.sp_RegresarAdmin');
  return replyByCode(res, r.output.outResultCode, { mensaje: 'Regreso registrado.' });
});

app.get('/api/planilla/semanal/:idEmpleado', async (req, res) => {
  const p = await getPool();
  const r = await p.request()
    .input('inIdEmpleado', sql.Int, Number(req.params.idEmpleado))
    .input('inTop', sql.Int, Number(req.query.top || 8))
    .input('inIdPostByUser', sql.Int, readUser(req))
    .input('inPostInIP', sql.VarChar(64), ip(req))
    .output('outResultCode', sql.Int)
    .execute('dbo.sp_ConsultarPlanillasSemanales');
  return replyByCode(res, r.output.outResultCode, { planillas: r.recordset || [] });
});

app.get('/api/planilla/semanal/deducciones/:idPlanilla', async (req, res) => {
  const p = await getPool();
  const r = await p.request()
    .input('inIdPlanillaSemanal', sql.Int, Number(req.params.idPlanilla))
    .input('inIdPostByUser', sql.Int, readUser(req))
    .input('inPostInIP', sql.VarChar(64), ip(req))
    .output('outResultCode', sql.Int)
    .execute('dbo.sp_ConsultarDetalleDeduccionesSemana');
  return replyByCode(res, r.output.outResultCode, { deducciones: r.recordset || [] });
});

app.get('/api/planilla/semanal/horas/:idPlanilla', async (req, res) => {
  const p = await getPool();
  const r = await p.request()
    .input('inIdPlanillaSemanal', sql.Int, Number(req.params.idPlanilla))
    .input('inIdPostByUser', sql.Int, readUser(req))
    .input('inPostInIP', sql.VarChar(64), ip(req))
    .output('outResultCode', sql.Int)
    .execute('dbo.sp_ConsultarDetalleHorasSemana');
  return replyByCode(res, r.output.outResultCode, { horas: r.recordset || [] });
});

app.get('/api/planilla/mensual/:idEmpleado', async (req, res) => {
  const p = await getPool();
  const r = await p.request()
    .input('inIdEmpleado', sql.Int, Number(req.params.idEmpleado))
    .input('inTop', sql.Int, Number(req.query.top || 6))
    .input('inIdPostByUser', sql.Int, readUser(req))
    .input('inPostInIP', sql.VarChar(64), ip(req))
    .output('outResultCode', sql.Int)
    .execute('dbo.sp_ConsultarPlanillasMensuales');
  return replyByCode(res, r.output.outResultCode, { planillas: r.recordset || [] });
});

app.get('/api/planilla/mensual/deducciones/:idPlanilla', async (req, res) => {
  const p = await getPool();
  const r = await p.request()
    .input('inIdPlanillaMensual', sql.Int, Number(req.params.idPlanilla))
    .input('inIdPostByUser', sql.Int, readUser(req))
    .input('inPostInIP', sql.VarChar(64), ip(req))
    .output('outResultCode', sql.Int)
    .execute('dbo.sp_ConsultarDetalleDeduccionesMes');
  return replyByCode(res, r.output.outResultCode, { deducciones: r.recordset || [] });
});

app.listen(PORT, '0.0.0.0', () => console.log(`Proyecto 3 disponible en http://localhost:${PORT}`));
