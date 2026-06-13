# Proyecto 3 - Control de asistencia y planilla obrera

Proyecto web y base de datos física para **Base de Datos 1**. La estructura sigue el enfoque del Proyecto 2 de referencia: SQL Server como motor, procedimientos almacenados para toda operación de base de datos, servidor Node.js/Express con `mssql`, y una interfaz web estática en `public/index.html`.

## Contenido

```text
Proyecto3_PlanillaObrera/
├── SQL/
│   ├── 00_CrearBaseDatos.sql
│   ├── 01_CargarCatalogos.sql
│   ├── 02_EjecutarSimulacion_Original.sql
│   ├── 02b_EjecutarSimulacion_Extendida5Meses.sql
│   ├── 03_Pruebas_Consultas.sql
│   └── 00_EjecutarTodo.sql
├── datos/
│   ├── Catalogos.xml
│   ├── Operaciones.xml
│   └── Operaciones_Extendida5Meses.xml
├── public/index.html
├── server.js
├── package.json
└── docs/
```

## Orden recomendado de ejecución

1. Abrir SQL Server Management Studio.
2. Ejecutar `SQL/00_CrearBaseDatos.sql`.
3. Ejecutar `SQL/01_CargarCatalogos.sql`.
4. Ejecutar una de estas simulaciones:
   - `SQL/02b_EjecutarSimulacion_Extendida5Meses.sql`: usa el XML subido y una extensión generada hasta el último jueves de julio de 2026 para cubrir la simulación de varios meses.
5. Ejecutar `SQL/03_Pruebas_Consultas.sql` para validar empleados, asistencias, movimientos, planillas y bitácora.

También puede ejecutarse con SQLCMD desde la carpeta `SQL`:

```powershell
sqlcmd -S localhost -E -i 00_EjecutarTodo.sql
```

## Ejecución del sitio web

```powershell
npm install
npm start
```

Luego abrir:

```text
http://localhost:3000
```

## Credenciales de prueba

Administrador:

```text
Usuario: admin
Contraseña: 1234
```

También se puede usar:

```text
Usuario: Goku
Contraseña: 1234
```

Empleados: los usuarios y contraseñas se cargan desde `Operaciones.xml`. Ejemplo:

```text
Usuario: Mencar
Contraseña: Gojira
```

## Conexión usada por Node.js

El script `00_CrearBaseDatos.sql` crea el login/usuario de aplicación:

```text
Servidor: localhost
Base de datos: PlanillaObreraDB
Usuario: developer_proyecto3
Contraseña: Proyecto3_2026!
```

Se puede modificar con variables de ambiente:

```powershell
$env:DB_SERVER="localhost"
$env:DB_DATABASE="PlanillaObreraDB"
$env:DB_USER="developer_proyecto3"
$env:DB_PASSWORD="Proyecto3_2026!"
npm start
```

## Alcance funcional cubierto

- Login por administrador o empleado.
- R01/R02: listar empleados y filtrar por nombre/documento en orden alfabético.
- CRUD básico de empleados desde administrador.
- R03/R06: impersonar empleado y regresar a interfaz de administrador.
- R04: consultar planillas semanales, detalle de deducciones y detalle de horas trabajadas.
- R05: consultar planillas mensuales y detalle de deducciones.
- R07: bitácora de eventos con usuario, IP, fecha, tipo de evento y JSON de parámetros.
- Trigger que asocia deducciones obligatorias al insertar empleado.
- Simulación por XML con inserción/eliminación de empleados, asistencia, jornadas, deducciones y cierres semanales/mensuales.

## Nota de honestidad técnica

Los scripts fueron generados de forma rigurosa, pero no pude ejecutar SQL Server dentro de este entorno. Antes de entregar, conviene correr los `.sql` en SSMS y revisar cualquier diferencia de configuración local de SQL Server, rutas, idioma o permisos.


## Corrección final aplicada

Esta versión final incorpora las correcciones de entrega solicitadas:

- La capa Node.js no contiene SQL incrustado: todas las rutas usan `request().execute(...)` contra procedimientos almacenados.
- La simulación se procesa desde `dbo.sp_EjecutarSimulacion`, leyendo el XML y delegando cada operación a SPs.
- Cada `FechaOperacion` se procesa dentro de una transacción de aplicación, agrupando altas/bajas, deducciones, asistencias, cierre semanal/mensual y asignación de jornadas. Si una operación falla, se revierte la fecha completa.
- Se eliminaron llamadas T-SQL inseguras con expresiones directas dentro de `EXEC` y se usan variables intermedias.
- Se mantiene salario por puesto y jornada mediante `PuestoJornadaSalario`.
- Se permite que el XML asigne una jornada a un empleado recién eliminado sin romper la simulación; se registra como evento histórico, pero no se crea planilla activa si la salida es anterior a la semana.
