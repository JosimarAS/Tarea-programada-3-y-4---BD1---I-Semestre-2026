USE master;
GO
IF DB_ID(N'PlanillaObreraDB') IS NOT NULL
BEGIN
    ALTER DATABASE PlanillaObreraDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE PlanillaObreraDB;
END;
GO
CREATE DATABASE PlanillaObreraDB;
GO
USE PlanillaObreraDB;
GO
SET NOCOUNT ON;
GO

CREATE TABLE dbo.TipoUsuario (
    Id INT NOT NULL CONSTRAINT PK_TipoUsuario PRIMARY KEY,
    Nombre VARCHAR(32) NOT NULL CONSTRAINT UQ_TipoUsuario_Nombre UNIQUE
);
GO
CREATE TABLE dbo.Puesto (
    Id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Puesto PRIMARY KEY,
    Nombre VARCHAR(80) NOT NULL CONSTRAINT UQ_Puesto_Nombre UNIQUE,
    SalarioXHora DECIMAL(18,2) NOT NULL CONSTRAINT CK_Puesto_Salario CHECK (SalarioXHora > 0)
);
GO
CREATE TABLE dbo.TipoJornada (
    Id INT NOT NULL CONSTRAINT PK_TipoJornada PRIMARY KEY,
    Nombre VARCHAR(40) NOT NULL CONSTRAINT UQ_TipoJornada_Nombre UNIQUE,
    HoraInicio TIME(0) NOT NULL,
    HoraFin TIME(0) NOT NULL
);
GO
CREATE TABLE dbo.PuestoJornadaSalario (
    IdPuesto INT NOT NULL CONSTRAINT FK_PuestoJornadaSalario_Puesto REFERENCES dbo.Puesto(Id),
    IdTipoJornada INT NOT NULL CONSTRAINT FK_PuestoJornadaSalario_TipoJornada REFERENCES dbo.TipoJornada(Id),
    SalarioXHora DECIMAL(18,2) NOT NULL CONSTRAINT CK_PuestoJornadaSalario_Salario CHECK (SalarioXHora > 0),
    CONSTRAINT PK_PuestoJornadaSalario PRIMARY KEY (IdPuesto, IdTipoJornada)
);
GO
CREATE TABLE dbo.Feriado (
    Id INT NOT NULL CONSTRAINT PK_Feriado PRIMARY KEY,
    Nombre VARCHAR(100) NOT NULL,
    Fecha DATE NOT NULL CONSTRAINT UQ_Feriado_Fecha UNIQUE
);
GO
CREATE TABLE dbo.TipoMovimiento (
    Id INT NOT NULL CONSTRAINT PK_TipoMovimiento PRIMARY KEY,
    Nombre VARCHAR(100) NOT NULL CONSTRAINT UQ_TipoMovimiento_Nombre UNIQUE,
    Accion CHAR(1) NOT NULL CONSTRAINT CK_TipoMovimiento_Accion CHECK (Accion IN ('+','-'))
);
GO
CREATE TABLE dbo.TipoDeduccion (
    Id INT NOT NULL CONSTRAINT PK_TipoDeduccion PRIMARY KEY,
    Nombre VARCHAR(100) NOT NULL CONSTRAINT UQ_TipoDeduccion_Nombre UNIQUE,
    Obligatorio BIT NOT NULL,
    Porcentual BIT NOT NULL,
    Valor DECIMAL(18,4) NOT NULL CONSTRAINT CK_TipoDeduccion_Valor CHECK (Valor >= 0),
    IdTipoMovimiento INT NOT NULL CONSTRAINT FK_TipoDeduccion_TipoMovimiento REFERENCES dbo.TipoMovimiento(Id)
);
GO
CREATE TABLE dbo.TipoEvento (
    Id INT NOT NULL CONSTRAINT PK_TipoEvento PRIMARY KEY,
    Nombre VARCHAR(100) NOT NULL CONSTRAINT UQ_TipoEvento_Nombre UNIQUE
);
GO
CREATE TABLE dbo.ErrorAplicacion (
    Codigo INT NOT NULL CONSTRAINT PK_ErrorAplicacion PRIMARY KEY,
    Descripcion VARCHAR(250) NOT NULL
);
GO
CREATE TABLE dbo.Empleado (
    Id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Empleado PRIMARY KEY,
    ValorDocumentoIdentidad VARCHAR(32) NOT NULL CONSTRAINT UQ_Empleado_Documento UNIQUE,
    Nombre VARCHAR(128) NOT NULL,
    IdPuesto INT NOT NULL CONSTRAINT FK_Empleado_Puesto REFERENCES dbo.Puesto(Id),
    CuentaBancaria VARCHAR(40) NOT NULL,
    FechaContratacion DATE NOT NULL,
    FechaSalida DATE NULL,
    Activo BIT NOT NULL CONSTRAINT DF_Empleado_Activo DEFAULT (1),
    PostTime DATETIME2(0) NOT NULL CONSTRAINT DF_Empleado_PostTime DEFAULT (SYSDATETIME())
);
GO
CREATE INDEX IX_Empleado_Nombre ON dbo.Empleado(Nombre);
GO
CREATE TABLE dbo.Usuario (
    Id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Usuario PRIMARY KEY,
    Username VARCHAR(64) NOT NULL CONSTRAINT UQ_Usuario_Username UNIQUE,
    Password VARCHAR(128) NOT NULL,
    IdTipoUsuario INT NOT NULL CONSTRAINT FK_Usuario_TipoUsuario REFERENCES dbo.TipoUsuario(Id),
    IdEmpleado INT NULL CONSTRAINT FK_Usuario_Empleado REFERENCES dbo.Empleado(Id),
    Activo BIT NOT NULL CONSTRAINT DF_Usuario_Activo DEFAULT (1),
    PostTime DATETIME2(0) NOT NULL CONSTRAINT DF_Usuario_PostTime DEFAULT (SYSDATETIME())
);
GO
CREATE TABLE dbo.EventLog (
    Id BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_EventLog PRIMARY KEY,
    IdUsuario INT NULL CONSTRAINT FK_EventLog_Usuario REFERENCES dbo.Usuario(Id),
    PostInIP VARCHAR(64) NOT NULL CONSTRAINT DF_EventLog_IP DEFAULT ('127.0.0.1'),
    PostTime DATETIME2(0) NOT NULL CONSTRAINT DF_EventLog_PostTime DEFAULT (SYSDATETIME()),
    IdTipoEvento INT NOT NULL CONSTRAINT FK_EventLog_TipoEvento REFERENCES dbo.TipoEvento(Id),
    ParametrosJson NVARCHAR(MAX) NULL,
    AntesJson NVARCHAR(MAX) NULL,
    DespuesJson NVARCHAR(MAX) NULL,
    Resultado VARCHAR(30) NOT NULL CONSTRAINT DF_EventLog_Resultado DEFAULT ('OK')
);
GO
CREATE TABLE dbo.MesPlanilla (
    Id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_MesPlanilla PRIMARY KEY,
    FechaInicio DATE NOT NULL,
    FechaFin DATE NOT NULL,
    CantidadSemanas INT NOT NULL CONSTRAINT CK_MesPlanilla_Semanas CHECK (CantidadSemanas IN (4,5)),
    Cerrado BIT NOT NULL CONSTRAINT DF_MesPlanilla_Cerrado DEFAULT (0),
    CONSTRAINT UQ_MesPlanilla_Fechas UNIQUE (FechaInicio, FechaFin)
);
GO
CREATE TABLE dbo.SemanaPlanilla (
    Id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_SemanaPlanilla PRIMARY KEY,
    IdMesPlanilla INT NOT NULL CONSTRAINT FK_SemanaPlanilla_MesPlanilla REFERENCES dbo.MesPlanilla(Id),
    FechaInicio DATE NOT NULL,
    FechaFin DATE NOT NULL,
    Cerrada BIT NOT NULL CONSTRAINT DF_SemanaPlanilla_Cerrada DEFAULT (0),
    CONSTRAINT UQ_SemanaPlanilla_Fechas UNIQUE (FechaInicio, FechaFin)
);
GO
CREATE TABLE dbo.PlanillaMesXEmpleado (
    Id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_PlanillaMesXEmpleado PRIMARY KEY,
    IdMesPlanilla INT NOT NULL CONSTRAINT FK_PlanillaMesXEmpleado_MesPlanilla REFERENCES dbo.MesPlanilla(Id),
    IdEmpleado INT NOT NULL CONSTRAINT FK_PlanillaMesXEmpleado_Empleado REFERENCES dbo.Empleado(Id),
    SalarioBruto DECIMAL(18,2) NOT NULL CONSTRAINT DF_PME_Bruto DEFAULT (0),
    TotalDeducciones DECIMAL(18,2) NOT NULL CONSTRAINT DF_PME_Deducciones DEFAULT (0),
    SalarioNeto AS (SalarioBruto - TotalDeducciones) PERSISTED,
    CONSTRAINT UQ_PlanillaMesXEmpleado UNIQUE (IdMesPlanilla, IdEmpleado)
);
GO
CREATE TABLE dbo.PlanillaSemXEmpleado (
    Id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_PlanillaSemXEmpleado PRIMARY KEY,
    IdSemanaPlanilla INT NOT NULL CONSTRAINT FK_PlanillaSemXEmpleado_SemanaPlanilla REFERENCES dbo.SemanaPlanilla(Id),
    IdEmpleado INT NOT NULL CONSTRAINT FK_PlanillaSemXEmpleado_Empleado REFERENCES dbo.Empleado(Id),
    SalarioBruto DECIMAL(18,2) NOT NULL CONSTRAINT DF_PSE_Bruto DEFAULT (0),
    TotalDeducciones DECIMAL(18,2) NOT NULL CONSTRAINT DF_PSE_Deducciones DEFAULT (0),
    SalarioNeto AS (SalarioBruto - TotalDeducciones) PERSISTED,
    HorasOrdinarias INT NOT NULL CONSTRAINT DF_PSE_HOrd DEFAULT (0),
    HorasExtraNormales INT NOT NULL CONSTRAINT DF_PSE_HExtra DEFAULT (0),
    HorasExtraDobles INT NOT NULL CONSTRAINT DF_PSE_HDoble DEFAULT (0),
    Cerrada BIT NOT NULL CONSTRAINT DF_PSE_Cerrada DEFAULT (0),
    CONSTRAINT UQ_PlanillaSemXEmpleado UNIQUE (IdSemanaPlanilla, IdEmpleado)
);
GO
CREATE TABLE dbo.EmpleadoDeduccion (
    Id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_EmpleadoDeduccion PRIMARY KEY,
    IdEmpleado INT NOT NULL CONSTRAINT FK_EmpleadoDeduccion_Empleado REFERENCES dbo.Empleado(Id),
    IdTipoDeduccion INT NOT NULL CONSTRAINT FK_EmpleadoDeduccion_TipoDeduccion REFERENCES dbo.TipoDeduccion(Id),
    Porcentaje DECIMAL(18,4) NULL,
    MontoFijo DECIMAL(18,2) NULL,
    FechaInicio DATE NOT NULL,
    FechaFin DATE NULL,
    Activo BIT NOT NULL CONSTRAINT DF_EmpleadoDeduccion_Activo DEFAULT (1),
    CONSTRAINT CK_EmpleadoDeduccion_Valor CHECK (Porcentaje IS NOT NULL OR MontoFijo IS NOT NULL)
);
GO
CREATE INDEX IX_EmpleadoDeduccion_Empleado ON dbo.EmpleadoDeduccion(IdEmpleado, IdTipoDeduccion, Activo);
GO
CREATE TABLE dbo.JornadaXEmpleado (
    Id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_JornadaXEmpleado PRIMARY KEY,
    IdEmpleado INT NOT NULL CONSTRAINT FK_JornadaXEmpleado_Empleado REFERENCES dbo.Empleado(Id),
    IdTipoJornada INT NOT NULL CONSTRAINT FK_JornadaXEmpleado_TipoJornada REFERENCES dbo.TipoJornada(Id),
    InicioSemana DATE NOT NULL,
    PostTime DATETIME2(0) NOT NULL CONSTRAINT DF_JornadaXEmpleado_PostTime DEFAULT (SYSDATETIME()),
    CONSTRAINT UQ_JornadaXEmpleado UNIQUE (IdEmpleado, InicioSemana)
);
GO
CREATE TABLE dbo.Asistencia (
    Id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Asistencia PRIMARY KEY,
    IdEmpleado INT NOT NULL CONSTRAINT FK_Asistencia_Empleado REFERENCES dbo.Empleado(Id),
    IdSemanaPlanilla INT NOT NULL CONSTRAINT FK_Asistencia_SemanaPlanilla REFERENCES dbo.SemanaPlanilla(Id),
    FechaOperacion DATE NOT NULL,
    HoraEntrada DATETIME2(0) NOT NULL,
    HoraSalida DATETIME2(0) NOT NULL,
    PostTime DATETIME2(0) NOT NULL CONSTRAINT DF_Asistencia_PostTime DEFAULT (SYSDATETIME()),
    CONSTRAINT CK_Asistencia_Horas CHECK (HoraSalida > HoraEntrada)
);
GO
CREATE TABLE dbo.MovimientoPlanilla (
    Id BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_MovimientoPlanilla PRIMARY KEY,
    IdEmpleado INT NOT NULL CONSTRAINT FK_MovimientoPlanilla_Empleado REFERENCES dbo.Empleado(Id),
    IdSemanaPlanilla INT NOT NULL CONSTRAINT FK_MovimientoPlanilla_SemanaPlanilla REFERENCES dbo.SemanaPlanilla(Id),
    IdMesPlanilla INT NOT NULL CONSTRAINT FK_MovimientoPlanilla_MesPlanilla REFERENCES dbo.MesPlanilla(Id),
    IdAsistencia INT NULL CONSTRAINT FK_MovimientoPlanilla_Asistencia REFERENCES dbo.Asistencia(Id),
    IdTipoMovimiento INT NOT NULL CONSTRAINT FK_MovimientoPlanilla_TipoMovimiento REFERENCES dbo.TipoMovimiento(Id),
    IdTipoDeduccion INT NULL CONSTRAINT FK_MovimientoPlanilla_TipoDeduccion REFERENCES dbo.TipoDeduccion(Id),
    FechaMovimiento DATE NOT NULL,
    CantidadHoras INT NULL,
    Monto DECIMAL(18,2) NOT NULL,
    Detalle VARCHAR(250) NULL,
    PostTime DATETIME2(0) NOT NULL CONSTRAINT DF_MovimientoPlanilla_PostTime DEFAULT (SYSDATETIME())
);
GO
CREATE INDEX IX_MovimientoPlanilla_EmpleadoSemana ON dbo.MovimientoPlanilla(IdEmpleado, IdSemanaPlanilla);
GO
CREATE TABLE dbo.MovimientoXHoras (
    IdMovimientoPlanilla BIGINT NOT NULL,
    IdAsistencia INT NOT NULL,
    CantidadHoras INT NOT NULL CONSTRAINT CK_MovimientoXHoras_Cantidad CHECK (CantidadHoras >= 0),
    CONSTRAINT PK_MovimientoXHoras PRIMARY KEY (IdMovimientoPlanilla),
    CONSTRAINT FK_MovimientoXHoras_MovimientoPlanilla FOREIGN KEY (IdMovimientoPlanilla) REFERENCES dbo.MovimientoPlanilla(Id),
    CONSTRAINT FK_MovimientoXHoras_Asistencia FOREIGN KEY (IdAsistencia) REFERENCES dbo.Asistencia(Id)
);
GO
CREATE TABLE dbo.MovimientoXDeduccion (
    IdMovimientoPlanilla BIGINT NOT NULL,
    IdTipoDeduccion INT NOT NULL,
    PorcentajeAplicado DECIMAL(18,4) NULL,
    MontoBase DECIMAL(18,2) NULL,
    CONSTRAINT PK_MovimientoXDeduccion PRIMARY KEY (IdMovimientoPlanilla),
    CONSTRAINT FK_MovimientoXDeduccion_MovimientoPlanilla FOREIGN KEY (IdMovimientoPlanilla) REFERENCES dbo.MovimientoPlanilla(Id),
    CONSTRAINT FK_MovimientoXDeduccion_TipoDeduccion FOREIGN KEY (IdTipoDeduccion) REFERENCES dbo.TipoDeduccion(Id)
);
GO
CREATE TABLE dbo.DeduccionXEmpleadoXMes (
    Id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_DeduccionXEmpleadoXMes PRIMARY KEY,
    IdMesPlanilla INT NOT NULL CONSTRAINT FK_DEM_MesPlanilla REFERENCES dbo.MesPlanilla(Id),
    IdEmpleado INT NOT NULL CONSTRAINT FK_DEM_Empleado REFERENCES dbo.Empleado(Id),
    IdTipoDeduccion INT NOT NULL CONSTRAINT FK_DEM_TipoDeduccion REFERENCES dbo.TipoDeduccion(Id),
    PorcentajeAplicado DECIMAL(18,4) NULL,
    Monto DECIMAL(18,2) NOT NULL CONSTRAINT DF_DEM_Monto DEFAULT (0),
    CONSTRAINT UQ_DeduccionXEmpleadoXMes UNIQUE (IdMesPlanilla, IdEmpleado, IdTipoDeduccion)
);
GO
CREATE TABLE dbo.TransferenciaDeduccionMes (
    Id BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_TransferenciaDeduccionMes PRIMARY KEY,
    IdMesPlanilla INT NOT NULL CONSTRAINT FK_TransferenciaDeduccionMes_MesPlanilla REFERENCES dbo.MesPlanilla(Id),
    IdTipoDeduccion INT NOT NULL CONSTRAINT FK_TransferenciaDeduccionMes_TipoDeduccion REFERENCES dbo.TipoDeduccion(Id),
    MontoTotal DECIMAL(18,2) NOT NULL,
    FechaTransferencia DATE NOT NULL,
    PostTime DATETIME2(0) NOT NULL CONSTRAINT DF_TransferenciaDeduccionMes_PostTime DEFAULT (SYSDATETIME()),
    CONSTRAINT UQ_TransferenciaDeduccionMes UNIQUE (IdMesPlanilla, IdTipoDeduccion)
);
GO

INSERT dbo.ErrorAplicacion (Codigo, Descripcion) VALUES
(0, 'Operacion correcta'),
(50001, 'Usuario no existe.'),
(50002, 'Password incorrecto.'),
(50003, 'Usuario deshabilitado.'),
(50004, 'Empleado con ValorDocumentoIdentidad ya existe.'),
(50005, 'Empleado con el mismo nombre ya existe.'),
(50006, 'Puesto no existe.'),
(50007, 'Empleado no existe.'),
(50008, 'Error de base de datos.'),
(50009, 'Tipo de deduccion no existe.'),
(50010, 'Tipo de jornada no existe.'),
(50011, 'Semana de planilla no existe.'),
(50012, 'Tipo de usuario invalido.'),
(50013, 'Operacion no permitida para el tipo de usuario.');
GO

CREATE OR ALTER FUNCTION dbo.fn_DiaSemana(@Fecha DATE)
RETURNS INT
AS
BEGIN
    RETURN ((DATEDIFF(DAY, CONVERT(DATE, '19000101'), @Fecha) % 7 + 7) % 7) + 1;
END;
GO
CREATE OR ALTER FUNCTION dbo.fn_EsDomingo(@Fecha DATE)
RETURNS BIT
AS
BEGIN
    RETURN CASE WHEN dbo.fn_DiaSemana(@Fecha) = 7 THEN 1 ELSE 0 END;
END;
GO
CREATE OR ALTER FUNCTION dbo.fn_EsJueves(@Fecha DATE)
RETURNS BIT
AS
BEGIN
    RETURN CASE WHEN dbo.fn_DiaSemana(@Fecha) = 4 THEN 1 ELSE 0 END;
END;
GO
CREATE OR ALTER FUNCTION dbo.fn_ViernesDeSemana(@Fecha DATE)
RETURNS DATE
AS
BEGIN
    DECLARE @Offset INT = ((DATEDIFF(DAY, CONVERT(DATE, '19000105'), @Fecha) % 7 + 7) % 7);
    RETURN DATEADD(DAY, -@Offset, @Fecha);
END;
GO
CREATE OR ALTER FUNCTION dbo.fn_SiguienteViernes(@Fecha DATE)
RETURNS DATE
AS
BEGIN
    DECLARE @Offset INT = ((DATEDIFF(DAY, CONVERT(DATE, '19000105'), @Fecha) % 7 + 7) % 7);
    DECLARE @Dias INT = CASE WHEN @Offset = 0 THEN 0 ELSE 7 - @Offset END;
    RETURN DATEADD(DAY, @Dias, @Fecha);
END;
GO
CREATE OR ALTER FUNCTION dbo.fn_UltimoJuevesDelMes(@Fecha DATE)
RETURNS DATE
AS
BEGIN
    DECLARE @Ultimo DATE = EOMONTH(@Fecha);
    WHILE dbo.fn_EsJueves(@Ultimo) = 0
        SET @Ultimo = DATEADD(DAY, -1, @Ultimo);
    RETURN @Ultimo;
END;
GO
CREATE OR ALTER FUNCTION dbo.fn_EsFeriado(@Fecha DATE)
RETURNS BIT
AS
BEGIN
    RETURN CASE WHEN EXISTS (SELECT 1 FROM dbo.Feriado WHERE Fecha = @Fecha) THEN 1 ELSE 0 END;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_ObtenerError
    @inCodigo INT,
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT Codigo, Descripcion FROM dbo.ErrorAplicacion WHERE Codigo = @inCodigo;
    SET @outResultCode = 0;
END;
GO









CREATE OR ALTER PROCEDURE dbo.sp_RegistrarEvento
    @inIdUsuario INT = NULL,
    @inPostInIP VARCHAR(64) = '127.0.0.1',
    @inNombreEvento VARCHAR(100),
    @inParametrosJson NVARCHAR(MAX) = NULL,
    @inAntesJson NVARCHAR(MAX) = NULL,
    @inDespuesJson NVARCHAR(MAX) = NULL,
    @inResultado VARCHAR(30) = 'OK'
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @IdTipoEvento INT;
    SELECT @IdTipoEvento = Id FROM dbo.TipoEvento WHERE Nombre = @inNombreEvento;
    IF @IdTipoEvento IS NULL
        RETURN;
    INSERT dbo.EventLog (IdUsuario, PostInIP, IdTipoEvento, ParametrosJson, AntesJson, DespuesJson, Resultado)
    VALUES (@inIdUsuario, ISNULL(@inPostInIP, '127.0.0.1'), @IdTipoEvento, @inParametrosJson, @inAntesJson, @inDespuesJson, @inResultado);
END;
GO









CREATE OR ALTER PROCEDURE dbo.sp_CargarCatalogos
    @inXml XML,
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @TiposUsuario TABLE (Id INT NOT NULL PRIMARY KEY, Nombre VARCHAR(32) NOT NULL);
        INSERT @TiposUsuario (Id, Nombre)
        SELECT N.value('@Id[1]','INT'), N.value('@Nombre[1]','VARCHAR(32)')
        FROM @inXml.nodes('/Catalogo/TiposUsuario/TipoUsuario') X(N);

        UPDATE T SET T.Nombre = S.Nombre
        FROM dbo.TipoUsuario T INNER JOIN @TiposUsuario S ON S.Id = T.Id;
        INSERT dbo.TipoUsuario (Id, Nombre)
        SELECT S.Id, S.Nombre FROM @TiposUsuario S
        WHERE NOT EXISTS (SELECT 1 FROM dbo.TipoUsuario T WHERE T.Id = S.Id);

        DECLARE @TiposJornada TABLE (Id INT NOT NULL PRIMARY KEY, Nombre VARCHAR(40) NOT NULL, HoraInicio TIME(0) NOT NULL, HoraFin TIME(0) NOT NULL);
        INSERT @TiposJornada (Id, Nombre, HoraInicio, HoraFin)
        SELECT N.value('@Id[1]','INT'), N.value('@Nombre[1]','VARCHAR(40)'), N.value('@HoraInicio[1]','TIME(0)'), N.value('@HoraFin[1]','TIME(0)')
        FROM @inXml.nodes('/Catalogo/TiposDeJornada/TipoDeJornada') X(N);

        UPDATE T SET T.Nombre = S.Nombre, T.HoraInicio = S.HoraInicio, T.HoraFin = S.HoraFin
        FROM dbo.TipoJornada T INNER JOIN @TiposJornada S ON S.Id = T.Id;
        INSERT dbo.TipoJornada (Id, Nombre, HoraInicio, HoraFin)
        SELECT S.Id, S.Nombre, S.HoraInicio, S.HoraFin FROM @TiposJornada S
        WHERE NOT EXISTS (SELECT 1 FROM dbo.TipoJornada T WHERE T.Id = S.Id);

        DECLARE @Puestos TABLE (Nombre VARCHAR(80) NOT NULL PRIMARY KEY, SalarioXHora DECIMAL(18,2) NOT NULL,
                                SalarioDiurno DECIMAL(18,2) NULL, SalarioVespertino DECIMAL(18,2) NULL, SalarioNocturno DECIMAL(18,2) NULL);
        INSERT @Puestos (Nombre, SalarioXHora, SalarioDiurno, SalarioVespertino, SalarioNocturno)
        SELECT N.value('@Nombre[1]','VARCHAR(80)'),
               N.value('@SalarioXHora[1]','DECIMAL(18,2)'),
               CASE WHEN N.exist('@SalarioDiurno') = 1 THEN N.value('@SalarioDiurno[1]','DECIMAL(18,2)') ELSE NULL END,
               CASE WHEN N.exist('@SalarioVespertino') = 1 THEN N.value('@SalarioVespertino[1]','DECIMAL(18,2)') ELSE NULL END,
               CASE WHEN N.exist('@SalarioNocturno') = 1 THEN N.value('@SalarioNocturno[1]','DECIMAL(18,2)') ELSE NULL END
        FROM @inXml.nodes('/Catalogo/Puestos/Puesto') X(N);

        UPDATE T SET T.SalarioXHora = S.SalarioXHora
        FROM dbo.Puesto T INNER JOIN @Puestos S ON S.Nombre = T.Nombre;
        INSERT dbo.Puesto (Nombre, SalarioXHora)
        SELECT S.Nombre, S.SalarioXHora FROM @Puestos S
        WHERE NOT EXISTS (SELECT 1 FROM dbo.Puesto T WHERE T.Nombre = S.Nombre);

        DECLARE @SalariosJornada TABLE (IdPuesto INT NOT NULL, IdTipoJornada INT NOT NULL, SalarioXHora DECIMAL(18,2) NOT NULL,
                                        PRIMARY KEY (IdPuesto, IdTipoJornada));
        INSERT @SalariosJornada (IdPuesto, IdTipoJornada, SalarioXHora)
        SELECT P.Id,
               TJ.Id,
               CASE
                   WHEN TJ.Nombre = 'Diurno' THEN ISNULL(S.SalarioDiurno, S.SalarioXHora)
                   WHEN TJ.Nombre = 'Vespertino' THEN ISNULL(S.SalarioVespertino, S.SalarioXHora)
                   WHEN TJ.Nombre = 'Nocturno' THEN ISNULL(S.SalarioNocturno, S.SalarioXHora)
                   ELSE S.SalarioXHora
               END
        FROM @Puestos S
        INNER JOIN dbo.Puesto P ON P.Nombre = S.Nombre
        CROSS JOIN dbo.TipoJornada TJ;

        UPDATE T SET T.SalarioXHora = S.SalarioXHora
        FROM dbo.PuestoJornadaSalario T INNER JOIN @SalariosJornada S ON S.IdPuesto = T.IdPuesto AND S.IdTipoJornada = T.IdTipoJornada;
        INSERT dbo.PuestoJornadaSalario (IdPuesto, IdTipoJornada, SalarioXHora)
        SELECT S.IdPuesto, S.IdTipoJornada, S.SalarioXHora FROM @SalariosJornada S
        WHERE NOT EXISTS (
            SELECT 1 FROM dbo.PuestoJornadaSalario T
            WHERE T.IdPuesto = S.IdPuesto AND T.IdTipoJornada = S.IdTipoJornada
        );

        DECLARE @Feriados TABLE (Id INT NOT NULL PRIMARY KEY, Nombre VARCHAR(100) NOT NULL, Fecha DATE NOT NULL);
        INSERT @Feriados (Id, Nombre, Fecha)
        SELECT N.value('@Id[1]','INT'), N.value('@Nombre[1]','VARCHAR(100)'), N.value('@Fecha[1]','DATE')
        FROM @inXml.nodes('/Catalogo/Feriados/Feriado') X(N);

        UPDATE T SET T.Nombre = S.Nombre, T.Fecha = S.Fecha
        FROM dbo.Feriado T INNER JOIN @Feriados S ON S.Id = T.Id;
        INSERT dbo.Feriado (Id, Nombre, Fecha)
        SELECT S.Id, S.Nombre, S.Fecha FROM @Feriados S
        WHERE NOT EXISTS (SELECT 1 FROM dbo.Feriado T WHERE T.Id = S.Id);

        DECLARE @TiposMovimiento TABLE (Id INT NOT NULL PRIMARY KEY, Nombre VARCHAR(100) NOT NULL, Accion CHAR(1) NOT NULL);
        INSERT @TiposMovimiento (Id, Nombre, Accion)
        SELECT N.value('@Id[1]','INT'), N.value('@Nombre[1]','VARCHAR(100)'), N.value('@Accion[1]','CHAR(1)')
        FROM @inXml.nodes('/Catalogo/TiposDeMovimiento/TipoDeMovimiento') X(N);

        UPDATE T SET T.Nombre = S.Nombre, T.Accion = S.Accion
        FROM dbo.TipoMovimiento T INNER JOIN @TiposMovimiento S ON S.Id = T.Id;
        INSERT dbo.TipoMovimiento (Id, Nombre, Accion)
        SELECT S.Id, S.Nombre, S.Accion FROM @TiposMovimiento S
        WHERE NOT EXISTS (SELECT 1 FROM dbo.TipoMovimiento T WHERE T.Id = S.Id);

        DECLARE @TiposDeduccion TABLE (Id INT NOT NULL PRIMARY KEY, Nombre VARCHAR(100) NOT NULL, Obligatorio BIT NOT NULL,
                                       Porcentual BIT NOT NULL, Valor DECIMAL(18,4) NOT NULL, IdTipoMovimiento INT NOT NULL);
        INSERT @TiposDeduccion (Id, Nombre, Obligatorio, Porcentual, Valor, IdTipoMovimiento)
        SELECT N.value('@Id[1]','INT'),
               N.value('@Nombre[1]','VARCHAR(100)'),
               CASE WHEN LOWER(N.value('@Obligatorio[1]','VARCHAR(10)')) IN ('si','sí','1','true') THEN CONVERT(BIT,1) ELSE CONVERT(BIT,0) END,
               CASE WHEN LOWER(N.value('@Porcentual[1]','VARCHAR(10)')) IN ('si','sí','1','true') THEN CONVERT(BIT,1) ELSE CONVERT(BIT,0) END,
               N.value('@Valor[1]','DECIMAL(18,4)'),
               N.value('@IdTipoMov[1]','INT')
        FROM @inXml.nodes('/Catalogo/TiposDeDeduccion/TipoDeDeduccion') X(N);

        UPDATE T
        SET T.Nombre = S.Nombre,
            T.Obligatorio = S.Obligatorio,
            T.Porcentual = S.Porcentual,
            T.Valor = S.Valor,
            T.IdTipoMovimiento = S.IdTipoMovimiento
        FROM dbo.TipoDeduccion T INNER JOIN @TiposDeduccion S ON S.Id = T.Id;
        INSERT dbo.TipoDeduccion (Id, Nombre, Obligatorio, Porcentual, Valor, IdTipoMovimiento)
        SELECT S.Id, S.Nombre, S.Obligatorio, S.Porcentual, S.Valor, S.IdTipoMovimiento FROM @TiposDeduccion S
        WHERE NOT EXISTS (SELECT 1 FROM dbo.TipoDeduccion T WHERE T.Id = S.Id);

        DECLARE @TiposEvento TABLE (Id INT NOT NULL PRIMARY KEY, Nombre VARCHAR(100) NOT NULL);
        INSERT @TiposEvento (Id, Nombre)
        SELECT N.value('@Id[1]','INT'), N.value('@Nombre[1]','VARCHAR(100)')
        FROM @inXml.nodes('/Catalogo/TiposDeEvento/TipoEvento') X(N);

        UPDATE T SET T.Nombre = S.Nombre
        FROM dbo.TipoEvento T INNER JOIN @TiposEvento S ON S.Id = T.Id;
        INSERT dbo.TipoEvento (Id, Nombre)
        SELECT S.Id, S.Nombre FROM @TiposEvento S
        WHERE NOT EXISTS (SELECT 1 FROM dbo.TipoEvento T WHERE T.Id = S.Id);

        DECLARE @Usuarios TABLE (Username VARCHAR(64) NOT NULL PRIMARY KEY, Password VARCHAR(128) NOT NULL, IdTipoUsuario INT NOT NULL);
        INSERT @Usuarios (Username, Password, IdTipoUsuario)
        SELECT N.value('@Username[1]','VARCHAR(64)'), N.value('@Password[1]','VARCHAR(128)'), N.value('@TipoUsuario[1]','INT')
        FROM @inXml.nodes('/Catalogo/Usuarios/Usuario') X(N);

        UPDATE T SET T.Password = S.Password, T.IdTipoUsuario = S.IdTipoUsuario, T.Activo = 1
        FROM dbo.Usuario T INNER JOIN @Usuarios S ON S.Username = T.Username;
        INSERT dbo.Usuario (Username, Password, IdTipoUsuario, IdEmpleado, Activo)
        SELECT S.Username, S.Password, S.IdTipoUsuario, NULL, 1 FROM @Usuarios S
        WHERE NOT EXISTS (SELECT 1 FROM dbo.Usuario T WHERE T.Username = S.Username);

        COMMIT TRANSACTION;
        SET @outResultCode = 0;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SET @outResultCode = 50008;
        THROW;
    END CATCH
END;
GO








CREATE OR ALTER TRIGGER dbo.trg_Empleado_AsociaDeduccionesObligatorias
ON dbo.Empleado
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    INSERT dbo.EmpleadoDeduccion (IdEmpleado, IdTipoDeduccion, Porcentaje, MontoFijo, FechaInicio, FechaFin, Activo)
    SELECT I.Id,
           TD.Id,
           CASE WHEN TD.Porcentual = 1 THEN TD.Valor ELSE NULL END,
           CASE WHEN TD.Porcentual = 0 THEN TD.Valor ELSE NULL END,
           I.FechaContratacion,
           NULL,
           1
    FROM inserted I
    CROSS JOIN dbo.TipoDeduccion TD
    WHERE TD.Obligatorio = 1
      AND NOT EXISTS (
          SELECT 1 FROM dbo.EmpleadoDeduccion ED
          WHERE ED.IdEmpleado = I.Id AND ED.IdTipoDeduccion = TD.Id AND ED.Activo = 1
      );

    INSERT dbo.EventLog (IdUsuario, PostInIP, IdTipoEvento, ParametrosJson, Resultado)
    SELECT NULL,
           'TRIGGER',
           TE.Id,
           CONCAT('{"EmpleadoId":', I.Id, ',"Tipo":"Deduccion obligatoria"}'),
           'OK'
    FROM inserted I
    CROSS JOIN dbo.TipoEvento TE
    WHERE TE.Nombre = 'Asociar deduccion';
END;
GO








CREATE OR ALTER PROCEDURE dbo.sp_LoginUsuario
    @inUsername VARCHAR(64),
    @inPassword VARCHAR(128),
    @inPostInIP VARCHAR(64),
    @outIdUsuario INT OUTPUT,
    @outIdEmpleado INT OUTPUT,
    @outTipoUsuario VARCHAR(32) OUTPUT,
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @LogJson NVARCHAR(MAX);
    SET @outIdUsuario = NULL;
    SET @outIdEmpleado = NULL;
    SET @outTipoUsuario = NULL;

    SELECT @outIdUsuario = U.Id, @outIdEmpleado = U.IdEmpleado, @outTipoUsuario = TU.Nombre
    FROM dbo.Usuario U
    INNER JOIN dbo.TipoUsuario TU ON TU.Id = U.IdTipoUsuario
    WHERE U.Username = @inUsername;

    IF @outIdUsuario IS NULL
    BEGIN
        SET @outResultCode = 50001;
        SET @LogJson = CONCAT('{"Username":"', @inUsername, '","Resultado":"No exitoso"}');
        EXEC dbo.sp_RegistrarEvento NULL, @inPostInIP, 'Login', @LogJson, NULL, NULL, 'ERROR';
        RETURN;
    END;
    IF EXISTS (SELECT 1 FROM dbo.Usuario WHERE Id = @outIdUsuario AND Activo = 0)
    BEGIN
        SET @outResultCode = 50003;
        SET @LogJson = CONCAT('{"Username":"', @inUsername, '","Resultado":"Usuario deshabilitado"}');
        EXEC dbo.sp_RegistrarEvento @outIdUsuario, @inPostInIP, 'Login', @LogJson, NULL, NULL, 'ERROR';
        RETURN;
    END;
    IF NOT EXISTS (SELECT 1 FROM dbo.Usuario WHERE Id = @outIdUsuario AND Password = @inPassword)
    BEGIN
        SET @outResultCode = 50002;
        SET @LogJson = CONCAT('{"Username":"', @inUsername, '","Resultado":"No exitoso"}');
        EXEC dbo.sp_RegistrarEvento @outIdUsuario, @inPostInIP, 'Login', @LogJson, NULL, NULL, 'ERROR';
        RETURN;
    END;

    SET @outResultCode = 0;
    SET @LogJson = CONCAT('{"Username":"', @inUsername, '","Resultado":"Exitoso"}');
    EXEC dbo.sp_RegistrarEvento @outIdUsuario, @inPostInIP, 'Login', @LogJson, NULL, NULL, 'OK';
END;
GO








CREATE OR ALTER PROCEDURE dbo.sp_LogoutUsuario
    @inIdUsuario INT,
    @inPostInIP VARCHAR(64),
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    EXEC dbo.sp_RegistrarEvento @inIdUsuario, @inPostInIP, 'Logout', NULL, NULL, NULL, 'OK';
    SET @outResultCode = 0;
END;
GO








CREATE OR ALTER PROCEDURE dbo.sp_AbrirMesSiNoExistePorSemana
    @inFechaInicioSemana DATE,
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        DECLARE @FechaFinSemana DATE = DATEADD(DAY, 6, @inFechaInicioSemana);
        DECLARE @FechaFinMes DATE = dbo.fn_UltimoJuevesDelMes(@FechaFinSemana);
        DECLARE @FechaFinMesAnterior DATE = dbo.fn_UltimoJuevesDelMes(DATEADD(MONTH, -1, @FechaFinMes));
        DECLARE @FechaInicioMes DATE = DATEADD(DAY, 1, @FechaFinMesAnterior);
        DECLARE @CantidadSemanas INT = ((DATEDIFF(DAY, @FechaInicioMes, @FechaFinMes) + 1) / 7);
        DECLARE @IdMesPlanilla INT;
        DECLARE @LogJson NVARCHAR(MAX);

        IF NOT EXISTS (SELECT 1 FROM dbo.MesPlanilla WHERE FechaInicio = @FechaInicioMes AND FechaFin = @FechaFinMes)
        BEGIN
            INSERT dbo.MesPlanilla (FechaInicio, FechaFin, CantidadSemanas)
            VALUES (@FechaInicioMes, @FechaFinMes, @CantidadSemanas);
            SET @LogJson = CONCAT('{"FechaInicio":"', CONVERT(VARCHAR(10), @FechaInicioMes, 120), '","FechaFin":"', CONVERT(VARCHAR(10), @FechaFinMes, 120), '"}');
            EXEC dbo.sp_RegistrarEvento NULL, 'SIMULACION', 'Apertura mensual', @LogJson, NULL, NULL, 'OK';
        END;

        SELECT @IdMesPlanilla = Id FROM dbo.MesPlanilla WHERE FechaInicio = @FechaInicioMes AND FechaFin = @FechaFinMes;

        INSERT dbo.PlanillaMesXEmpleado (IdMesPlanilla, IdEmpleado)
        SELECT @IdMesPlanilla, E.Id
        FROM dbo.Empleado E
        WHERE E.FechaContratacion <= @FechaFinMes
          AND (E.FechaSalida IS NULL OR E.FechaSalida >= @FechaInicioMes)
          AND NOT EXISTS (SELECT 1 FROM dbo.PlanillaMesXEmpleado PME WHERE PME.IdMesPlanilla = @IdMesPlanilla AND PME.IdEmpleado = E.Id);

        SET @outResultCode = 0;
    END TRY
    BEGIN CATCH
        SET @outResultCode = 50008;
        THROW;
    END CATCH
END;
GO








CREATE OR ALTER PROCEDURE dbo.sp_AbrirSemanaSiNoExiste
    @inFechaInicioSemana DATE,
    @outIdSemanaPlanilla INT OUTPUT,
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        DECLARE @tmpCode INT;
        DECLARE @FechaFinSemana DATE = DATEADD(DAY, 6, @inFechaInicioSemana);
        DECLARE @IdMesPlanilla INT;
        DECLARE @LogJson NVARCHAR(MAX);

        EXEC dbo.sp_AbrirMesSiNoExistePorSemana @inFechaInicioSemana, @tmpCode OUTPUT;
        IF @tmpCode <> 0
        BEGIN
            SET @outResultCode = @tmpCode;
            RETURN;
        END;

        SELECT @IdMesPlanilla = MP.Id
        FROM dbo.MesPlanilla MP
        WHERE @FechaFinSemana BETWEEN MP.FechaInicio AND MP.FechaFin;

        IF NOT EXISTS (SELECT 1 FROM dbo.SemanaPlanilla WHERE FechaInicio = @inFechaInicioSemana)
        BEGIN
            INSERT dbo.SemanaPlanilla (IdMesPlanilla, FechaInicio, FechaFin)
            VALUES (@IdMesPlanilla, @inFechaInicioSemana, @FechaFinSemana);
            SET @LogJson = CONCAT('{"FechaInicio":"', CONVERT(VARCHAR(10), @inFechaInicioSemana, 120), '","FechaFin":"', CONVERT(VARCHAR(10), @FechaFinSemana, 120), '"}');
            EXEC dbo.sp_RegistrarEvento NULL, 'SIMULACION', 'Apertura semanal', @LogJson, NULL, NULL, 'OK';
        END;

        SELECT @outIdSemanaPlanilla = Id FROM dbo.SemanaPlanilla WHERE FechaInicio = @inFechaInicioSemana;

        INSERT dbo.PlanillaSemXEmpleado (IdSemanaPlanilla, IdEmpleado)
        SELECT @outIdSemanaPlanilla, E.Id
        FROM dbo.Empleado E
        WHERE E.FechaContratacion <= @FechaFinSemana
          AND (E.FechaSalida IS NULL OR E.FechaSalida >= @inFechaInicioSemana)
          AND NOT EXISTS (SELECT 1 FROM dbo.PlanillaSemXEmpleado PSE WHERE PSE.IdSemanaPlanilla = @outIdSemanaPlanilla AND PSE.IdEmpleado = E.Id);

        SET @outResultCode = 0;
    END TRY
    BEGIN CATCH
        SET @outResultCode = 50008;
        THROW;
    END CATCH
END;
GO








CREATE OR ALTER PROCEDURE dbo.sp_InsertarEmpleado
    @inValorDocumentoIdentidad VARCHAR(32),
    @inNombre VARCHAR(128),
    @inIdPuesto INT,
    @inCuentaBancaria VARCHAR(40),
    @inUsername VARCHAR(64),
    @inPassword VARCHAR(128),
    @inIdTipoUsuario INT,
    @inFechaContratacion DATE,
    @inIdPostByUser INT = NULL,
    @inPostInIP VARCHAR(64) = '127.0.0.1',
    @outIdEmpleado INT OUTPUT,
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @LogJson NVARCHAR(MAX), @Despues NVARCHAR(MAX), @InicioTransaccion BIT = 0;
    SET @outIdEmpleado = NULL;
    IF EXISTS (SELECT 1 FROM dbo.Empleado WHERE ValorDocumentoIdentidad = @inValorDocumentoIdentidad)
    BEGIN SET @outResultCode = 50004; RETURN; END;
    IF NOT EXISTS (SELECT 1 FROM dbo.Puesto WHERE Id = @inIdPuesto)
    BEGIN SET @outResultCode = 50006; RETURN; END;
    IF NOT EXISTS (SELECT 1 FROM dbo.TipoUsuario WHERE Id = @inIdTipoUsuario)
    BEGIN SET @outResultCode = 50012; RETURN; END;

    BEGIN TRY
        IF @@TRANCOUNT = 0 BEGIN SET @InicioTransaccion = 1; BEGIN TRANSACTION; END;

        INSERT dbo.Empleado (ValorDocumentoIdentidad, Nombre, IdPuesto, CuentaBancaria, FechaContratacion)
        VALUES (@inValorDocumentoIdentidad, @inNombre, @inIdPuesto, @inCuentaBancaria, @inFechaContratacion);
        SET @outIdEmpleado = SCOPE_IDENTITY();

        INSERT dbo.Usuario (Username, Password, IdTipoUsuario, IdEmpleado, Activo)
        VALUES (@inUsername, @inPassword, @inIdTipoUsuario, CASE WHEN @inIdTipoUsuario = 0 THEN @outIdEmpleado ELSE NULL END, 1);

        SET @LogJson = CONCAT('{"Documento":"', @inValorDocumentoIdentidad, '","Nombre":"', @inNombre, '"}');
        SELECT @Despues = (SELECT E.Id, E.ValorDocumentoIdentidad, E.Nombre, E.IdPuesto, E.CuentaBancaria, E.FechaContratacion FROM dbo.Empleado E WHERE E.Id = @outIdEmpleado FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);
        EXEC dbo.sp_RegistrarEvento @inIdPostByUser, @inPostInIP, 'Insertar empleado', @LogJson, NULL, @Despues, 'OK';

        IF @InicioTransaccion = 1 COMMIT TRANSACTION;
        SET @outResultCode = 0;
    END TRY
    BEGIN CATCH
        IF @InicioTransaccion = 1 AND @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SET @outResultCode = 50008;
        THROW;
    END CATCH
END;
GO








CREATE OR ALTER PROCEDURE dbo.sp_InsertarEmpleadoSim
    @inValorDocumentoIdentidad VARCHAR(32),
    @inNombre VARCHAR(128),
    @inPuesto VARCHAR(80),
    @inCuentaBancaria VARCHAR(40),
    @inUsername VARCHAR(64),
    @inPassword VARCHAR(128),
    @inTipoUsuario INT,
    @inFechaContratacion DATE,
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @IdPuesto INT, @IdEmpleado INT;
    SELECT @IdPuesto = Id FROM dbo.Puesto WHERE Nombre = @inPuesto;
    IF @IdPuesto IS NULL BEGIN SET @outResultCode = 50006; RETURN; END;
    EXEC dbo.sp_InsertarEmpleado @inValorDocumentoIdentidad, @inNombre, @IdPuesto, @inCuentaBancaria, @inUsername, @inPassword, @inTipoUsuario, @inFechaContratacion, NULL, 'SIMULACION', @IdEmpleado OUTPUT, @outResultCode OUTPUT;
END;
GO








CREATE OR ALTER PROCEDURE dbo.sp_EliminarEmpleado
    @inValorDocumentoIdentidad VARCHAR(32) = NULL,
    @inIdEmpleado INT = NULL,
    @inFechaSalida DATE = NULL,
    @inIdPostByUser INT = NULL,
    @inPostInIP VARCHAR(64) = '127.0.0.1',
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @Antes NVARCHAR(MAX), @Despues NVARCHAR(MAX), @LogJson NVARCHAR(MAX), @InicioTransaccion BIT = 0;
    IF @inIdEmpleado IS NULL
        SELECT @inIdEmpleado = Id FROM dbo.Empleado WHERE ValorDocumentoIdentidad = @inValorDocumentoIdentidad;
    IF @inIdEmpleado IS NULL BEGIN SET @outResultCode = 50007; RETURN; END;

    SELECT @Antes = (SELECT * FROM dbo.Empleado WHERE Id = @inIdEmpleado FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);
    BEGIN TRY
        IF @@TRANCOUNT = 0 BEGIN SET @InicioTransaccion = 1; BEGIN TRANSACTION; END;

        UPDATE dbo.Empleado SET Activo = 0, FechaSalida = ISNULL(@inFechaSalida, CAST(SYSDATETIME() AS DATE)) WHERE Id = @inIdEmpleado;
        UPDATE dbo.Usuario SET Activo = 0 WHERE IdEmpleado = @inIdEmpleado;

        DELETE PSE
        FROM dbo.PlanillaSemXEmpleado PSE
        INNER JOIN dbo.SemanaPlanilla SP ON SP.Id = PSE.IdSemanaPlanilla
        WHERE PSE.IdEmpleado = @inIdEmpleado
          AND SP.FechaInicio > ISNULL(@inFechaSalida, CAST(SYSDATETIME() AS DATE))
          AND PSE.SalarioBruto = 0
          AND PSE.TotalDeducciones = 0
          AND PSE.HorasOrdinarias = 0
          AND PSE.HorasExtraNormales = 0
          AND PSE.HorasExtraDobles = 0;

        SET @LogJson = CONCAT('{"IdEmpleado":', @inIdEmpleado, '}');
        SELECT @Despues = (SELECT * FROM dbo.Empleado WHERE Id = @inIdEmpleado FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);
        EXEC dbo.sp_RegistrarEvento @inIdPostByUser, @inPostInIP, 'Eliminar empleado', @LogJson, @Antes, @Despues, 'OK';

        IF @InicioTransaccion = 1 COMMIT TRANSACTION;
        SET @outResultCode = 0;
    END TRY
    BEGIN CATCH
        IF @InicioTransaccion = 1 AND @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SET @outResultCode = 50008;
        THROW;
    END CATCH
END;
GO








CREATE OR ALTER PROCEDURE dbo.sp_ActualizarEmpleado
    @inIdEmpleado INT,
    @inValorDocumentoIdentidad VARCHAR(32),
    @inNombre VARCHAR(128),
    @inIdPuesto INT,
    @inCuentaBancaria VARCHAR(40),
    @inIdPostByUser INT,
    @inPostInIP VARCHAR(64),
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @Antes NVARCHAR(MAX), @Despues NVARCHAR(MAX), @LogJson NVARCHAR(MAX);
    IF NOT EXISTS (SELECT 1 FROM dbo.Empleado WHERE Id = @inIdEmpleado) BEGIN SET @outResultCode = 50007; RETURN; END;
    IF NOT EXISTS (SELECT 1 FROM dbo.Puesto WHERE Id = @inIdPuesto) BEGIN SET @outResultCode = 50006; RETURN; END;
    IF EXISTS (SELECT 1 FROM dbo.Empleado WHERE ValorDocumentoIdentidad = @inValorDocumentoIdentidad AND Id <> @inIdEmpleado) BEGIN SET @outResultCode = 50004; RETURN; END;

    SELECT @Antes = (SELECT * FROM dbo.Empleado WHERE Id = @inIdEmpleado FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);
    BEGIN TRY
        BEGIN TRANSACTION;
        UPDATE dbo.Empleado
        SET ValorDocumentoIdentidad = @inValorDocumentoIdentidad, Nombre = @inNombre, IdPuesto = @inIdPuesto, CuentaBancaria = @inCuentaBancaria
        WHERE Id = @inIdEmpleado;
        SET @LogJson = CONCAT('{"IdEmpleado":', @inIdEmpleado, '}');
        SELECT @Despues = (SELECT * FROM dbo.Empleado WHERE Id = @inIdEmpleado FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);
        EXEC dbo.sp_RegistrarEvento @inIdPostByUser, @inPostInIP, 'Editar empleado', @LogJson, @Antes, @Despues, 'OK';
        COMMIT TRANSACTION;
        SET @outResultCode = 0;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SET @outResultCode = 50008;
        THROW;
    END CATCH
END;
GO








CREATE OR ALTER PROCEDURE dbo.sp_ListarPuestos
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT P.Id,
           P.Nombre,
           P.SalarioXHora,
           MAX(CASE WHEN TJ.Nombre = 'Diurno' THEN PJS.SalarioXHora END) AS SalarioDiurno,
           MAX(CASE WHEN TJ.Nombre = 'Vespertino' THEN PJS.SalarioXHora END) AS SalarioVespertino,
           MAX(CASE WHEN TJ.Nombre = 'Nocturno' THEN PJS.SalarioXHora END) AS SalarioNocturno
    FROM dbo.Puesto P
    LEFT JOIN dbo.PuestoJornadaSalario PJS ON PJS.IdPuesto = P.Id
    LEFT JOIN dbo.TipoJornada TJ ON TJ.Id = PJS.IdTipoJornada
    GROUP BY P.Id, P.Nombre, P.SalarioXHora
    ORDER BY P.Nombre;
    SET @outResultCode = 0;
END;
GO








CREATE OR ALTER PROCEDURE dbo.sp_ListarEmpleados
    @inFiltro VARCHAR(128) = '',
    @inIdPostByUser INT = NULL,
    @inPostInIP VARCHAR(64) = '127.0.0.1',
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @NombreEvento VARCHAR(100), @LogJson NVARCHAR(MAX);
    SET @inFiltro = ISNULL(@inFiltro, '');
    SELECT E.Id, E.ValorDocumentoIdentidad, E.Nombre, P.Nombre AS Puesto, E.CuentaBancaria, E.FechaContratacion, E.Activo
    FROM dbo.Empleado E
    INNER JOIN dbo.Puesto P ON P.Id = E.IdPuesto
    WHERE E.Activo = 1
      AND (@inFiltro = '' OR E.Nombre LIKE '%' + @inFiltro + '%' OR E.ValorDocumentoIdentidad LIKE '%' + @inFiltro + '%')
    ORDER BY E.Nombre;
    SET @NombreEvento = CASE WHEN @inFiltro = '' THEN 'Listar empleados' ELSE 'Listar empleados con filtro' END;
    SET @LogJson = CASE WHEN @inFiltro = '' THEN NULL ELSE CONCAT('{"Filtro":"', @inFiltro, '"}') END;
    EXEC dbo.sp_RegistrarEvento @inIdPostByUser, @inPostInIP, @NombreEvento, @LogJson, NULL, NULL, 'OK';
    SET @outResultCode = 0;
END;
GO








CREATE OR ALTER PROCEDURE dbo.sp_ObtenerEmpleado
    @inIdEmpleado INT,
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT E.Id, E.ValorDocumentoIdentidad, E.Nombre, E.IdPuesto, P.Nombre AS Puesto, E.CuentaBancaria, E.FechaContratacion, E.FechaSalida, E.Activo,
           U.Username
    FROM dbo.Empleado E
    INNER JOIN dbo.Puesto P ON P.Id = E.IdPuesto
    LEFT JOIN dbo.Usuario U ON U.IdEmpleado = E.Id
    WHERE E.Id = @inIdEmpleado;
    SET @outResultCode = CASE WHEN @@ROWCOUNT = 0 THEN 50007 ELSE 0 END;
END;
GO








CREATE OR ALTER PROCEDURE dbo.sp_ImpersonarEmpleado
    @inIdEmpleado INT,
    @inIdPostByUser INT,
    @inPostInIP VARCHAR(64),
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @LogJson NVARCHAR(MAX);
    IF NOT EXISTS (SELECT 1 FROM dbo.Empleado WHERE Id = @inIdEmpleado AND Activo = 1) BEGIN SET @outResultCode = 50007; RETURN; END;
    SET @LogJson = CONCAT('{"IdEmpleado":', @inIdEmpleado, '}');
    EXEC dbo.sp_RegistrarEvento @inIdPostByUser, @inPostInIP, 'Impersonar empleado', @LogJson, NULL, NULL, 'OK';
    SELECT E.Id AS IdEmpleado, E.Nombre, U.Username
    FROM dbo.Empleado E LEFT JOIN dbo.Usuario U ON U.IdEmpleado = E.Id
    WHERE E.Id = @inIdEmpleado;
    SET @outResultCode = 0;
END;
GO








CREATE OR ALTER PROCEDURE dbo.sp_RegresarAdmin
    @inIdPostByUser INT,
    @inPostInIP VARCHAR(64),
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    EXEC dbo.sp_RegistrarEvento @inIdPostByUser, @inPostInIP, 'Regresar a interfaz de administrador', NULL, NULL, NULL, 'OK';
    SET @outResultCode = 0;
END;
GO








CREATE OR ALTER PROCEDURE dbo.sp_AsociarDeduccionEmpleado
    @inIdEmpleado INT,
    @inIdTipoDeduccion INT,
    @inPorcentajeOMonto DECIMAL(18,4),
    @inFechaInicio DATE,
    @inIdPostByUser INT = NULL,
    @inPostInIP VARCHAR(64) = '127.0.0.1',
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @LogJson NVARCHAR(MAX), @InicioTransaccion BIT = 0;
    IF NOT EXISTS (SELECT 1 FROM dbo.Empleado WHERE Id = @inIdEmpleado) BEGIN SET @outResultCode = 50007; RETURN; END;
    IF NOT EXISTS (SELECT 1 FROM dbo.TipoDeduccion WHERE Id = @inIdTipoDeduccion AND Obligatorio = 0) BEGIN SET @outResultCode = 50009; RETURN; END;

    DECLARE @Porcentual BIT, @ValorDefault DECIMAL(18,4);
    SELECT @Porcentual = Porcentual, @ValorDefault = Valor FROM dbo.TipoDeduccion WHERE Id = @inIdTipoDeduccion;

    BEGIN TRY
        IF @@TRANCOUNT = 0 BEGIN SET @InicioTransaccion = 1; BEGIN TRANSACTION; END;

        UPDATE dbo.EmpleadoDeduccion
        SET Activo = 0, FechaFin = DATEADD(DAY, -1, @inFechaInicio)
        WHERE IdEmpleado = @inIdEmpleado AND IdTipoDeduccion = @inIdTipoDeduccion AND Activo = 1;

        INSERT dbo.EmpleadoDeduccion (IdEmpleado, IdTipoDeduccion, Porcentaje, MontoFijo, FechaInicio, FechaFin, Activo)
        VALUES (@inIdEmpleado, @inIdTipoDeduccion,
                CASE WHEN @Porcentual = 1 THEN CASE WHEN @inPorcentajeOMonto > 0 THEN @inPorcentajeOMonto ELSE @ValorDefault END ELSE NULL END,
                CASE WHEN @Porcentual = 0 THEN @inPorcentajeOMonto ELSE NULL END,
                @inFechaInicio, NULL, 1);

        SET @LogJson = CONCAT('{"IdEmpleado":', @inIdEmpleado, ',"IdTipoDeduccion":', @inIdTipoDeduccion, ',"Valor":', @inPorcentajeOMonto, '}');
        EXEC dbo.sp_RegistrarEvento @inIdPostByUser, @inPostInIP, 'Asociar deduccion', @LogJson, NULL, NULL, 'OK';

        IF @InicioTransaccion = 1 COMMIT TRANSACTION;
        SET @outResultCode = 0;
    END TRY
    BEGIN CATCH
        IF @InicioTransaccion = 1 AND @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SET @outResultCode = 50008;
        THROW;
    END CATCH
END;
GO








CREATE OR ALTER PROCEDURE dbo.sp_AsociarDeduccionEmpleadoSim
    @inValorDocumentoIdentidad VARCHAR(32),
    @inTipoDeduccion VARCHAR(100),
    @inMontoFijo DECIMAL(18,2),
    @inFechaOperacion DATE,
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @IdEmpleado INT, @IdTipoDeduccion INT, @FechaInicio DATE;
    SELECT @IdEmpleado = Id FROM dbo.Empleado WHERE ValorDocumentoIdentidad = @inValorDocumentoIdentidad;
    SELECT @IdTipoDeduccion = Id FROM dbo.TipoDeduccion WHERE Nombre = @inTipoDeduccion;
    SET @FechaInicio = dbo.fn_SiguienteViernes(@inFechaOperacion);
    EXEC dbo.sp_AsociarDeduccionEmpleado @IdEmpleado, @IdTipoDeduccion, @inMontoFijo, @FechaInicio, NULL, 'SIMULACION', @outResultCode OUTPUT;
END;
GO








CREATE OR ALTER PROCEDURE dbo.sp_DesasociarDeduccionEmpleadoSim
    @inValorDocumentoIdentidad VARCHAR(32),
    @inTipoDeduccion VARCHAR(100),
    @inFechaOperacion DATE,
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @IdEmpleado INT, @IdTipoDeduccion INT, @FechaFin DATE, @LogJson NVARCHAR(MAX), @InicioTransaccion BIT = 0;
    SELECT @IdEmpleado = Id FROM dbo.Empleado WHERE ValorDocumentoIdentidad = @inValorDocumentoIdentidad;
    SELECT @IdTipoDeduccion = Id FROM dbo.TipoDeduccion WHERE Nombre = @inTipoDeduccion AND Obligatorio = 0;
    IF @IdEmpleado IS NULL BEGIN SET @outResultCode = 50007; RETURN; END;
    IF @IdTipoDeduccion IS NULL BEGIN SET @outResultCode = 50009; RETURN; END;
    SET @FechaFin = DATEADD(DAY, -1, dbo.fn_SiguienteViernes(@inFechaOperacion));
    BEGIN TRY
        IF @@TRANCOUNT = 0 BEGIN SET @InicioTransaccion = 1; BEGIN TRANSACTION; END;

        UPDATE dbo.EmpleadoDeduccion SET Activo = 0, FechaFin = @FechaFin
        WHERE IdEmpleado = @IdEmpleado AND IdTipoDeduccion = @IdTipoDeduccion AND Activo = 1;
        SET @LogJson = CONCAT('{"IdEmpleado":', @IdEmpleado, ',"IdTipoDeduccion":', @IdTipoDeduccion, '}');
        EXEC dbo.sp_RegistrarEvento NULL, 'SIMULACION', 'Desasociar deduccion', @LogJson, NULL, NULL, 'OK';

        IF @InicioTransaccion = 1 COMMIT TRANSACTION;
        SET @outResultCode = 0;
    END TRY
    BEGIN CATCH
        IF @InicioTransaccion = 1 AND @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SET @outResultCode = 50008;
        THROW;
    END CATCH
END;
GO








CREATE OR ALTER PROCEDURE dbo.sp_AsignarJornadaEmpleado
    @inValorDocumentoIdentidad VARCHAR(32),
    @inJornada VARCHAR(40),
    @inInicioSemana DATE,
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @IdEmpleado INT, @IdTipoJornada INT, @IdSemana INT, @FechaSalida DATE, @tmpCode INT, @LogJson NVARCHAR(MAX), @InicioTransaccion BIT = 0;
    SELECT @IdEmpleado = Id, @FechaSalida = FechaSalida FROM dbo.Empleado WHERE ValorDocumentoIdentidad = @inValorDocumentoIdentidad;
    SELECT @IdTipoJornada = Id FROM dbo.TipoJornada WHERE Nombre = @inJornada;
    IF @IdEmpleado IS NULL BEGIN SET @outResultCode = 50007; RETURN; END;
    IF @IdTipoJornada IS NULL BEGIN SET @outResultCode = 50010; RETURN; END;

    BEGIN TRY
        IF @@TRANCOUNT = 0 BEGIN SET @InicioTransaccion = 1; BEGIN TRANSACTION; END;

        EXEC dbo.sp_AbrirSemanaSiNoExiste @inInicioSemana, @IdSemana OUTPUT, @tmpCode OUTPUT;
        IF @tmpCode <> 0
        BEGIN
            SET @outResultCode = @tmpCode;
            IF @InicioTransaccion = 1 AND @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
            RETURN;
        END;

        IF EXISTS (SELECT 1 FROM dbo.JornadaXEmpleado WHERE IdEmpleado = @IdEmpleado AND InicioSemana = @inInicioSemana)
            UPDATE dbo.JornadaXEmpleado SET IdTipoJornada = @IdTipoJornada WHERE IdEmpleado = @IdEmpleado AND InicioSemana = @inInicioSemana;
        ELSE
            INSERT dbo.JornadaXEmpleado (IdEmpleado, IdTipoJornada, InicioSemana) VALUES (@IdEmpleado, @IdTipoJornada, @inInicioSemana);

        IF (@FechaSalida IS NULL OR @FechaSalida >= @inInicioSemana)
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM dbo.PlanillaSemXEmpleado WHERE IdSemanaPlanilla = @IdSemana AND IdEmpleado = @IdEmpleado)
                INSERT dbo.PlanillaSemXEmpleado (IdSemanaPlanilla, IdEmpleado) VALUES (@IdSemana, @IdEmpleado);
        END;

        SET @LogJson = CONCAT('{"IdEmpleado":', @IdEmpleado, ',"IdTipoJornada":', @IdTipoJornada, ',"InicioSemana":"', CONVERT(VARCHAR(10), @inInicioSemana, 120), '"}');
        EXEC dbo.sp_RegistrarEvento NULL, 'SIMULACION', 'Ingreso nuevas jornadas', @LogJson, NULL, NULL, 'OK';

        IF @InicioTransaccion = 1 COMMIT TRANSACTION;
        SET @outResultCode = 0;
    END TRY
    BEGIN CATCH
        IF @InicioTransaccion = 1 AND @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SET @outResultCode = 50008;
        THROW;
    END CATCH
END;
GO








CREATE OR ALTER PROCEDURE dbo.sp_ProcesarMarcaAsistencia
    @inValorDocumentoIdentidad VARCHAR(32),
    @inFechaOperacion DATE,
    @inHoraEntrada DATETIME2(0),
    @inHoraSalida DATETIME2(0),
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @IdEmpleado INT, @IdSemana INT, @IdMes INT, @IdAsistencia INT, @IdPuesto INT, @IdTipoJornada INT,
            @SalarioXHora DECIMAL(18,2), @FechaInicioSemana DATE, @FechaInicioSemanaJornada DATE, @HoraInicio TIME(0), @HoraFin TIME(0),
            @DtInicioJornada DATETIME2(0), @DtFinJornada DATETIME2(0), @HorasTrabajadas INT,
            @HorasOrd INT, @HorasExtra INT, @HorasExtraNormal INT, @HorasExtraDoble INT,
            @MontoOrd DECIMAL(18,2), @MontoExtraNormal DECIMAL(18,2), @MontoExtraDoble DECIMAL(18,2),
            @TotalDevengado DECIMAL(18,2), @tmpCode INT, @LogJson NVARCHAR(MAX), @InicioTransaccion BIT = 0,
            @IdMovimiento BIGINT, @HoraExtraInicio DATETIME2(0), @IndiceHoraExtra INT;

    SELECT @IdEmpleado = E.Id, @IdPuesto = E.IdPuesto
    FROM dbo.Empleado E
    WHERE E.ValorDocumentoIdentidad = @inValorDocumentoIdentidad AND E.Activo = 1;
    IF @IdEmpleado IS NULL BEGIN SET @outResultCode = 50007; RETURN; END;

    SET @FechaInicioSemanaJornada = dbo.fn_ViernesDeSemana(CAST(@inHoraEntrada AS DATE));

    SELECT TOP (1) @HoraInicio = TJ.HoraInicio, @HoraFin = TJ.HoraFin, @IdTipoJornada = TJ.Id
    FROM dbo.JornadaXEmpleado JE
    INNER JOIN dbo.TipoJornada TJ ON TJ.Id = JE.IdTipoJornada
    WHERE JE.IdEmpleado = @IdEmpleado AND JE.InicioSemana <= @FechaInicioSemanaJornada
    ORDER BY JE.InicioSemana DESC;

    IF @HoraInicio IS NULL
    BEGIN
        SELECT @HoraInicio = HoraInicio, @HoraFin = HoraFin, @IdTipoJornada = Id FROM dbo.TipoJornada WHERE Nombre = 'Diurno';
    END;

    SET @DtInicioJornada = DATEADD(SECOND, DATEDIFF(SECOND, CAST('00:00:00' AS TIME), @HoraInicio), CAST(@inFechaOperacion AS DATETIME2(0)));
    SET @DtFinJornada = DATEADD(SECOND, DATEDIFF(SECOND, CAST('00:00:00' AS TIME), @HoraFin), CAST(@inFechaOperacion AS DATETIME2(0)));
    IF @HoraFin <= @HoraInicio SET @DtFinJornada = DATEADD(DAY, 1, @DtFinJornada);

    SET @FechaInicioSemana = dbo.fn_ViernesDeSemana(CAST(@DtFinJornada AS DATE));

    SELECT @SalarioXHora = PJS.SalarioXHora
    FROM dbo.PuestoJornadaSalario PJS
    WHERE PJS.IdPuesto = @IdPuesto AND PJS.IdTipoJornada = @IdTipoJornada;

    IF @SalarioXHora IS NULL
        SELECT @SalarioXHora = SalarioXHora FROM dbo.Puesto WHERE Id = @IdPuesto;

    BEGIN TRY
        IF @@TRANCOUNT = 0 BEGIN SET @InicioTransaccion = 1; BEGIN TRANSACTION; END;

        EXEC dbo.sp_AbrirSemanaSiNoExiste @FechaInicioSemana, @IdSemana OUTPUT, @tmpCode OUTPUT;
        IF @tmpCode <> 0
        BEGIN
            SET @outResultCode = @tmpCode;
            IF @InicioTransaccion = 1 AND @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
            RETURN;
        END;

        SELECT @IdMes = IdMesPlanilla FROM dbo.SemanaPlanilla WHERE Id = @IdSemana;

        SET @HorasTrabajadas = FLOOR(CAST(DATEDIFF(MINUTE, @inHoraEntrada, @inHoraSalida) AS DECIMAL(9,2)) / 60.0);
        SET @HorasOrd = CASE WHEN @HorasTrabajadas >= 8 THEN 8 ELSE @HorasTrabajadas END;
        SET @HorasExtra = CASE WHEN @inHoraSalida > @DtFinJornada THEN FLOOR(CAST(DATEDIFF(MINUTE, @DtFinJornada, @inHoraSalida) AS DECIMAL(9,2)) / 60.0) ELSE 0 END;
        IF @HorasExtra < 0 SET @HorasExtra = 0;

        SET @HorasExtraNormal = 0;
        SET @HorasExtraDoble = 0;
        SET @IndiceHoraExtra = 0;
        WHILE @IndiceHoraExtra < @HorasExtra
        BEGIN
            SET @HoraExtraInicio = DATEADD(HOUR, @IndiceHoraExtra, @DtFinJornada);
            IF dbo.fn_EsDomingo(CAST(@HoraExtraInicio AS DATE)) = 1 OR dbo.fn_EsFeriado(CAST(@HoraExtraInicio AS DATE)) = 1
                SET @HorasExtraDoble = @HorasExtraDoble + 1;
            ELSE
                SET @HorasExtraNormal = @HorasExtraNormal + 1;
            SET @IndiceHoraExtra = @IndiceHoraExtra + 1;
        END;

        SET @MontoOrd = ROUND(@HorasOrd * @SalarioXHora, 2);
        SET @MontoExtraNormal = ROUND(@HorasExtraNormal * @SalarioXHora * 1.5, 2);
        SET @MontoExtraDoble = ROUND(@HorasExtraDoble * @SalarioXHora * 2.0, 2);
        SET @TotalDevengado = @MontoOrd + @MontoExtraNormal + @MontoExtraDoble;

        INSERT dbo.Asistencia (IdEmpleado, IdSemanaPlanilla, FechaOperacion, HoraEntrada, HoraSalida)
        VALUES (@IdEmpleado, @IdSemana, @inFechaOperacion, @inHoraEntrada, @inHoraSalida);
        SET @IdAsistencia = SCOPE_IDENTITY();

        IF @HorasOrd > 0
        BEGIN
            INSERT dbo.MovimientoPlanilla (IdEmpleado, IdSemanaPlanilla, IdMesPlanilla, IdAsistencia, IdTipoMovimiento, FechaMovimiento, CantidadHoras, Monto, Detalle)
            VALUES (@IdEmpleado, @IdSemana, @IdMes, @IdAsistencia, 1, @inFechaOperacion, @HorasOrd, @MontoOrd, 'Horas ordinarias');
            SET @IdMovimiento = SCOPE_IDENTITY();
            INSERT dbo.MovimientoXHoras (IdMovimientoPlanilla, IdAsistencia, CantidadHoras)
            VALUES (@IdMovimiento, @IdAsistencia, @HorasOrd);
        END;
        IF @HorasExtraNormal > 0
        BEGIN
            INSERT dbo.MovimientoPlanilla (IdEmpleado, IdSemanaPlanilla, IdMesPlanilla, IdAsistencia, IdTipoMovimiento, FechaMovimiento, CantidadHoras, Monto, Detalle)
            VALUES (@IdEmpleado, @IdSemana, @IdMes, @IdAsistencia, 2, @inFechaOperacion, @HorasExtraNormal, @MontoExtraNormal, 'Horas extra normales');
            SET @IdMovimiento = SCOPE_IDENTITY();
            INSERT dbo.MovimientoXHoras (IdMovimientoPlanilla, IdAsistencia, CantidadHoras)
            VALUES (@IdMovimiento, @IdAsistencia, @HorasExtraNormal);
        END;
        IF @HorasExtraDoble > 0
        BEGIN
            INSERT dbo.MovimientoPlanilla (IdEmpleado, IdSemanaPlanilla, IdMesPlanilla, IdAsistencia, IdTipoMovimiento, FechaMovimiento, CantidadHoras, Monto, Detalle)
            VALUES (@IdEmpleado, @IdSemana, @IdMes, @IdAsistencia, 3, @inFechaOperacion, @HorasExtraDoble, @MontoExtraDoble, 'Horas extra dobles');
            SET @IdMovimiento = SCOPE_IDENTITY();
            INSERT dbo.MovimientoXHoras (IdMovimientoPlanilla, IdAsistencia, CantidadHoras)
            VALUES (@IdMovimiento, @IdAsistencia, @HorasExtraDoble);
        END;

        UPDATE dbo.PlanillaSemXEmpleado
        SET SalarioBruto = SalarioBruto + @TotalDevengado,
            HorasOrdinarias = HorasOrdinarias + @HorasOrd,
            HorasExtraNormales = HorasExtraNormales + @HorasExtraNormal,
            HorasExtraDobles = HorasExtraDobles + @HorasExtraDoble
        WHERE IdSemanaPlanilla = @IdSemana AND IdEmpleado = @IdEmpleado;

        UPDATE dbo.PlanillaMesXEmpleado
        SET SalarioBruto = SalarioBruto + @TotalDevengado
        WHERE IdMesPlanilla = @IdMes AND IdEmpleado = @IdEmpleado;

        SET @LogJson = CONCAT('{"IdEmpleado":', @IdEmpleado,
                              ',"SemanaPlanilla":"', CONVERT(VARCHAR(10), @FechaInicioSemana, 120),
                              '","SemanaJornada":"', CONVERT(VARCHAR(10), @FechaInicioSemanaJornada, 120),
                              '","Entrada":"', CONVERT(VARCHAR(19), @inHoraEntrada, 120),
                              '","Salida":"', CONVERT(VARCHAR(19), @inHoraSalida, 120), '"}');
        EXEC dbo.sp_RegistrarEvento NULL, 'SIMULACION', 'Ingreso de marcas de asistencia', @LogJson, NULL, NULL, 'OK';

        IF @InicioTransaccion = 1 COMMIT TRANSACTION;
        SET @outResultCode = 0;
    END TRY
    BEGIN CATCH
        IF @InicioTransaccion = 1 AND @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SET @outResultCode = 50008;
        THROW;
    END CATCH
END;
GO









CREATE OR ALTER PROCEDURE dbo.sp_CerrarMesSiCorresponde
    @inFechaOperacion DATE,
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @IdMesPlanilla INT, @LogJson NVARCHAR(MAX), @InicioTransaccion BIT = 0;

    SELECT @IdMesPlanilla = Id
    FROM dbo.MesPlanilla
    WHERE FechaFin = @inFechaOperacion AND Cerrado = 0;

    IF @IdMesPlanilla IS NULL
    BEGIN
        SET @outResultCode = 0;
        RETURN;
    END;

    BEGIN TRY
        IF @@TRANCOUNT = 0 BEGIN SET @InicioTransaccion = 1; BEGIN TRANSACTION; END;

        DECLARE @Totales TABLE (Fila INT IDENTITY(1,1) PRIMARY KEY, IdTipoDeduccion INT NOT NULL, MontoTotal DECIMAL(18,2) NOT NULL);
        DECLARE @Fila INT = 1, @TotalFilas INT, @IdTipoDeduccion INT, @MontoTotal DECIMAL(18,2);

        INSERT @Totales (IdTipoDeduccion, MontoTotal)
        SELECT IdTipoDeduccion, SUM(Monto) AS MontoTotal
        FROM dbo.DeduccionXEmpleadoXMes
        WHERE IdMesPlanilla = @IdMesPlanilla
        GROUP BY IdTipoDeduccion;

        SELECT @TotalFilas = COUNT(*) FROM @Totales;
        WHILE @Fila <= @TotalFilas
        BEGIN
            SELECT @IdTipoDeduccion = IdTipoDeduccion, @MontoTotal = MontoTotal FROM @Totales WHERE Fila = @Fila;

            IF EXISTS (SELECT 1 FROM dbo.TransferenciaDeduccionMes WHERE IdMesPlanilla = @IdMesPlanilla AND IdTipoDeduccion = @IdTipoDeduccion)
                UPDATE dbo.TransferenciaDeduccionMes
                SET MontoTotal = @MontoTotal, FechaTransferencia = @inFechaOperacion
                WHERE IdMesPlanilla = @IdMesPlanilla AND IdTipoDeduccion = @IdTipoDeduccion;
            ELSE
                INSERT dbo.TransferenciaDeduccionMes (IdMesPlanilla, IdTipoDeduccion, MontoTotal, FechaTransferencia)
                VALUES (@IdMesPlanilla, @IdTipoDeduccion, @MontoTotal, @inFechaOperacion);

            SET @Fila = @Fila + 1;
        END;

        UPDATE dbo.MesPlanilla
        SET Cerrado = 1
        WHERE Id = @IdMesPlanilla;

        SET @LogJson = CONCAT('{"IdMesPlanilla":', @IdMesPlanilla, ',"FechaCierre":"', CONVERT(VARCHAR(10), @inFechaOperacion, 120), '"}');
        EXEC dbo.sp_RegistrarEvento NULL, 'SIMULACION', 'Cierre mensual', @LogJson, NULL, NULL, 'OK';

        IF @InicioTransaccion = 1 COMMIT TRANSACTION;
        SET @outResultCode = 0;
    END TRY
    BEGIN CATCH
        IF @InicioTransaccion = 1 AND @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SET @outResultCode = 50008;
        THROW;
    END CATCH
END;
GO








CREATE OR ALTER PROCEDURE dbo.sp_CerrarSemanaEmpleado
    @inFechaOperacion DATE,
    @inValorDocumentoIdentidad VARCHAR(32),
    @inEsPrimerEmpleado BIT = 0,
    @inEsUltimoEmpleado BIT = 0,
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @FechaInicioSemana DATE = dbo.fn_ViernesDeSemana(@inFechaOperacion),
            @IdSemana INT,
            @IdMes INT,
            @IdEmpleado INT,
            @Bruto DECIMAL(18,2),
            @CantidadSemanas INT,
            @IdNuevaSemana INT,
            @tmp INT,
            @FechaInicioNuevaSemana DATE,
            @LogJson NVARCHAR(MAX),
            @InicioTransaccion BIT = 0;

    SELECT @IdEmpleado = Id FROM dbo.Empleado WHERE ValorDocumentoIdentidad = @inValorDocumentoIdentidad;
    IF @IdEmpleado IS NULL BEGIN SET @outResultCode = 50007; RETURN; END;

    SELECT @IdSemana = SP.Id, @IdMes = SP.IdMesPlanilla
    FROM dbo.SemanaPlanilla SP
    WHERE SP.FechaInicio = @FechaInicioSemana;

    IF @IdSemana IS NULL
    BEGIN
        SET @outResultCode = 0;
        RETURN;
    END;

    SELECT @CantidadSemanas = CantidadSemanas FROM dbo.MesPlanilla WHERE Id = @IdMes;
    SELECT @Bruto = SalarioBruto
    FROM dbo.PlanillaSemXEmpleado
    WHERE IdSemanaPlanilla = @IdSemana AND IdEmpleado = @IdEmpleado AND Cerrada = 0;

    BEGIN TRY
        IF @@TRANCOUNT = 0 BEGIN SET @InicioTransaccion = 1; BEGIN TRANSACTION; END;

        IF @Bruto IS NOT NULL
        BEGIN
            DECLARE @Deducciones TABLE (
                Fila INT IDENTITY(1,1) PRIMARY KEY,
                IdTipoDeduccion INT NOT NULL,
                IdTipoMovimiento INT NOT NULL,
                Porcentual BIT NOT NULL,
                Porcentaje DECIMAL(18,4) NULL,
                MontoFijo DECIMAL(18,2) NULL,
                MontoDeduccion DECIMAL(18,2) NOT NULL,
                NombreDeduccion VARCHAR(100) NOT NULL
            );
            DECLARE @Fila INT = 1,
                    @TotalFilas INT,
                    @IdTipoDeduccion INT,
                    @IdTipoMovimiento INT,
                    @Porcentual BIT,
                    @Porcentaje DECIMAL(18,4),
                    @MontoFijo DECIMAL(18,2),
                    @MontoDeduccion DECIMAL(18,2),
                    @NombreDeduccion VARCHAR(100),
                    @IdMovimiento BIGINT;

            INSERT @Deducciones (IdTipoDeduccion, IdTipoMovimiento, Porcentual, Porcentaje, MontoFijo, MontoDeduccion, NombreDeduccion)
            SELECT TD.Id,
                   TD.IdTipoMovimiento,
                   TD.Porcentual,
                   CASE WHEN TD.Porcentual = 1 THEN ISNULL(ED.Porcentaje, TD.Valor) ELSE NULL END,
                   ED.MontoFijo,
                   CASE WHEN TD.Porcentual = 1
                        THEN ROUND(@Bruto * ISNULL(ED.Porcentaje, TD.Valor), 2)
                        ELSE ROUND(ISNULL(ED.MontoFijo, TD.Valor) / @CantidadSemanas, 2)
                   END,
                   TD.Nombre
            FROM dbo.EmpleadoDeduccion ED
            INNER JOIN dbo.TipoDeduccion TD ON TD.Id = ED.IdTipoDeduccion
            WHERE ED.IdEmpleado = @IdEmpleado
              AND ED.FechaInicio <= @inFechaOperacion
              AND (ED.FechaFin IS NULL OR ED.FechaFin >= @FechaInicioSemana);

            SELECT @TotalFilas = COUNT(*) FROM @Deducciones;
            WHILE @Fila <= @TotalFilas
            BEGIN
                SELECT @IdTipoDeduccion = IdTipoDeduccion,
                       @IdTipoMovimiento = IdTipoMovimiento,
                       @Porcentual = Porcentual,
                       @Porcentaje = Porcentaje,
                       @MontoFijo = MontoFijo,
                       @MontoDeduccion = MontoDeduccion,
                       @NombreDeduccion = NombreDeduccion
                FROM @Deducciones
                WHERE Fila = @Fila;

                IF @MontoDeduccion > 0
                BEGIN
                    INSERT dbo.MovimientoPlanilla (IdEmpleado, IdSemanaPlanilla, IdMesPlanilla, IdTipoMovimiento, IdTipoDeduccion, FechaMovimiento, CantidadHoras, Monto, Detalle)
                    VALUES (@IdEmpleado, @IdSemana, @IdMes, @IdTipoMovimiento, @IdTipoDeduccion, @inFechaOperacion, NULL, @MontoDeduccion, @NombreDeduccion);
                    SET @IdMovimiento = SCOPE_IDENTITY();

                    INSERT dbo.MovimientoXDeduccion (IdMovimientoPlanilla, IdTipoDeduccion, PorcentajeAplicado, MontoBase)
                    VALUES (@IdMovimiento, @IdTipoDeduccion, CASE WHEN @Porcentual = 1 THEN @Porcentaje ELSE NULL END, CASE WHEN @Porcentual = 1 THEN @Bruto ELSE NULL END);

                    UPDATE dbo.PlanillaSemXEmpleado
                    SET TotalDeducciones = TotalDeducciones + @MontoDeduccion
                    WHERE IdSemanaPlanilla = @IdSemana AND IdEmpleado = @IdEmpleado;

                    UPDATE dbo.PlanillaMesXEmpleado
                    SET TotalDeducciones = TotalDeducciones + @MontoDeduccion
                    WHERE IdMesPlanilla = @IdMes AND IdEmpleado = @IdEmpleado;

                    IF EXISTS (SELECT 1 FROM dbo.DeduccionXEmpleadoXMes WHERE IdMesPlanilla = @IdMes AND IdEmpleado = @IdEmpleado AND IdTipoDeduccion = @IdTipoDeduccion)
                        UPDATE dbo.DeduccionXEmpleadoXMes
                        SET Monto = Monto + @MontoDeduccion,
                            PorcentajeAplicado = CASE WHEN @Porcentual = 1 THEN @Porcentaje ELSE PorcentajeAplicado END
                        WHERE IdMesPlanilla = @IdMes AND IdEmpleado = @IdEmpleado AND IdTipoDeduccion = @IdTipoDeduccion;
                    ELSE
                        INSERT dbo.DeduccionXEmpleadoXMes (IdMesPlanilla, IdEmpleado, IdTipoDeduccion, PorcentajeAplicado, Monto)
                        VALUES (@IdMes, @IdEmpleado, @IdTipoDeduccion, CASE WHEN @Porcentual = 1 THEN @Porcentaje ELSE NULL END, @MontoDeduccion);
                END;

                SET @Fila = @Fila + 1;
            END;

            UPDATE dbo.PlanillaSemXEmpleado
            SET Cerrada = 1
            WHERE IdSemanaPlanilla = @IdSemana AND IdEmpleado = @IdEmpleado;

            SET @LogJson = CONCAT('{"IdEmpleado":', @IdEmpleado, ',"IdSemanaPlanilla":', @IdSemana, ',"FechaInicio":"', CONVERT(VARCHAR(10), @FechaInicioSemana, 120), '","FechaFin":"', CONVERT(VARCHAR(10), @inFechaOperacion, 120), '"}');
            EXEC dbo.sp_RegistrarEvento NULL, 'SIMULACION', 'Cierre semanal', @LogJson, NULL, NULL, 'OK';
        END;

        IF @inEsPrimerEmpleado = 1
        BEGIN
            SET @FechaInicioNuevaSemana = DATEADD(DAY, 1, @inFechaOperacion);
            EXEC dbo.sp_AbrirSemanaSiNoExiste @FechaInicioNuevaSemana, @IdNuevaSemana OUTPUT, @tmp OUTPUT;
            IF @tmp <> 0
            BEGIN
                SET @outResultCode = @tmp;
                IF @InicioTransaccion = 1 AND @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
                RETURN;
            END;
        END;

        IF @inEsUltimoEmpleado = 1
        BEGIN
            UPDATE dbo.SemanaPlanilla SET Cerrada = 1 WHERE Id = @IdSemana;

            EXEC dbo.sp_CerrarMesSiCorresponde @inFechaOperacion, @tmp OUTPUT;
            IF @tmp <> 0
            BEGIN
                SET @outResultCode = @tmp;
                IF @InicioTransaccion = 1 AND @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
                RETURN;
            END;
        END;

        IF @InicioTransaccion = 1 COMMIT TRANSACTION;
        SET @outResultCode = 0;
    END TRY
    BEGIN CATCH
        IF @InicioTransaccion = 1 AND @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SET @outResultCode = 50008;
        THROW;
    END CATCH
END;
GO








CREATE OR ALTER PROCEDURE dbo.sp_CerrarSemana
    @inFechaOperacion DATE,
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @FechaInicioSemana DATE = dbo.fn_ViernesDeSemana(@inFechaOperacion),
            @IdSemana INT,
            @tmp INT,
            @Fila INT = 1,
            @TotalFilas INT,
            @Documento VARCHAR(32),
            @EsPrimerEmpleado BIT,
            @EsUltimoEmpleado BIT;

    SELECT @IdSemana = Id FROM dbo.SemanaPlanilla WHERE FechaInicio = @FechaInicioSemana;
    IF @IdSemana IS NULL BEGIN SET @outResultCode = 0; RETURN; END;

    DECLARE @Empleados TABLE (Fila INT IDENTITY(1,1) PRIMARY KEY, ValorDocumentoIdentidad VARCHAR(32) NOT NULL UNIQUE);
    INSERT @Empleados (ValorDocumentoIdentidad)
    SELECT E.ValorDocumentoIdentidad
    FROM dbo.PlanillaSemXEmpleado PSE
    INNER JOIN dbo.Empleado E ON E.Id = PSE.IdEmpleado
    WHERE PSE.IdSemanaPlanilla = @IdSemana AND PSE.Cerrada = 0
    ORDER BY E.ValorDocumentoIdentidad;

    SELECT @TotalFilas = COUNT(*) FROM @Empleados;
    WHILE @Fila <= @TotalFilas
    BEGIN
        SELECT @Documento = ValorDocumentoIdentidad FROM @Empleados WHERE Fila = @Fila;
        SET @EsPrimerEmpleado = CASE WHEN @Fila = 1 THEN 1 ELSE 0 END;
        SET @EsUltimoEmpleado = CASE WHEN @Fila = @TotalFilas THEN 1 ELSE 0 END;
        EXEC dbo.sp_CerrarSemanaEmpleado @inFechaOperacion, @Documento, @EsPrimerEmpleado, @EsUltimoEmpleado, @tmp OUTPUT;
        IF @tmp <> 0 BEGIN SET @outResultCode = @tmp; RETURN; END;
        SET @Fila = @Fila + 1;
    END;

    SET @outResultCode = 0;
END;
GO









CREATE OR ALTER PROCEDURE dbo.sp_ProcesarEmpleadoFechaOperacion
    @inFechaOperacion DATE,
    @inFechaNode XML,
    @inValorDocumentoIdentidad VARCHAR(32),
    @inEsPrimerEmpleado BIT = 0,
    @inEsUltimoEmpleado BIT = 0,
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @InicioTransaccion BIT = 0,
            @tmp INT = 0,
            @Fila INT,
            @TotalFilas INT,
            @Puesto VARCHAR(80),
            @Nombre VARCHAR(128),
            @CuentaBancaria VARCHAR(40),
            @Username VARCHAR(64),
            @Password VARCHAR(128),
            @TipoUsuario INT,
            @FechaContratacion DATE,
            @TipoDeduccion VARCHAR(100),
            @MontoFijo DECIMAL(18,2),
            @HoraEntrada DATETIME2(0),
            @HoraSalida DATETIME2(0),
            @Jornada VARCHAR(40),
            @InicioSemana DATE;

    BEGIN TRY
        IF @@TRANCOUNT = 0
        BEGIN
            SET @InicioTransaccion = 1;
            BEGIN TRANSACTION;
        END;

        /* 1. Inserciones del empleado de esta fecha */
        DECLARE @Insertar TABLE (
            Fila INT IDENTITY(1,1) PRIMARY KEY,
            Nombre VARCHAR(128) NOT NULL,
            Puesto VARCHAR(80) NOT NULL,
            CuentaBancaria VARCHAR(40) NOT NULL,
            Username VARCHAR(64) NOT NULL,
            Password VARCHAR(128) NOT NULL,
            TipoUsuario INT NOT NULL,
            FechaContratacion DATE NOT NULL
        );

        INSERT @Insertar (Nombre, Puesto, CuentaBancaria, Username, Password, TipoUsuario, FechaContratacion)
        SELECT N.value('@Nombre[1]','VARCHAR(128)'),
               N.value('@Puesto[1]','VARCHAR(80)'),
               N.value('@CuentaBancaria[1]','VARCHAR(40)'),
               N.value('@Username[1]','VARCHAR(64)'),
               N.value('@Password[1]','VARCHAR(128)'),
               N.value('@TipoUsuario[1]','INT'),
               N.value('@FechaContratacion[1]','DATE')
        FROM @inFechaNode.nodes('/FechaOperacion/InsertarEmpleado') X(N)
        WHERE N.value('@ValorDocumentoIdentidad[1]','VARCHAR(32)') = @inValorDocumentoIdentidad;

        SET @Fila = 1;
        SELECT @TotalFilas = COUNT(*) FROM @Insertar;
        WHILE @Fila <= @TotalFilas
        BEGIN
            SELECT @Nombre = Nombre,
                   @Puesto = Puesto,
                   @CuentaBancaria = CuentaBancaria,
                   @Username = Username,
                   @Password = Password,
                   @TipoUsuario = TipoUsuario,
                   @FechaContratacion = FechaContratacion
            FROM @Insertar
            WHERE Fila = @Fila;

            EXEC dbo.sp_InsertarEmpleadoSim
                @inValorDocumentoIdentidad,
                @Nombre,
                @Puesto,
                @CuentaBancaria,
                @Username,
                @Password,
                @TipoUsuario,
                @FechaContratacion,
                @tmp OUTPUT;

            IF @tmp <> 0
            BEGIN
                SET @outResultCode = @tmp;
                IF @InicioTransaccion = 1 AND @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
                RETURN;
            END;

            SET @Fila = @Fila + 1;
        END;



        /* 2. Asociaciones de deducciones aplicables desde el siguiente viernes */
        DECLARE @Asociar TABLE (
            Fila INT IDENTITY(1,1) PRIMARY KEY,
            TipoDeduccion VARCHAR(100) NOT NULL,
            MontoFijo DECIMAL(18,2) NOT NULL
        );

        INSERT @Asociar (TipoDeduccion, MontoFijo)
        SELECT N.value('@TipoDeduccion[1]','VARCHAR(100)'),
               N.value('@MontoFijo[1]','DECIMAL(18,2)')
        FROM @inFechaNode.nodes('/FechaOperacion/AsociaEmpleadoConDeduccion') X(N)
        WHERE N.value('@ValorDocumentoIdentidad[1]','VARCHAR(32)') = @inValorDocumentoIdentidad;

        SET @Fila = 1;
        SELECT @TotalFilas = COUNT(*) FROM @Asociar;
        WHILE @Fila <= @TotalFilas
        BEGIN
            SELECT @TipoDeduccion = TipoDeduccion,
                   @MontoFijo = MontoFijo
            FROM @Asociar
            WHERE Fila = @Fila;

            EXEC dbo.sp_AsociarDeduccionEmpleadoSim
                @inValorDocumentoIdentidad,
                @TipoDeduccion,
                @MontoFijo,
                @inFechaOperacion,
                @tmp OUTPUT;

            IF @tmp <> 0
            BEGIN
                SET @outResultCode = @tmp;
                IF @InicioTransaccion = 1 AND @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
                RETURN;
            END;

            SET @Fila = @Fila + 1;
        END;



        /* 3. Desasociaciones de deducciones aplicables desde el siguiente viernes */
        DECLARE @Desasociar TABLE (
            Fila INT IDENTITY(1,1) PRIMARY KEY,
            TipoDeduccion VARCHAR(100) NOT NULL
        );

        INSERT @Desasociar (TipoDeduccion)
        SELECT N.value('@TipoDeduccion[1]','VARCHAR(100)')
        FROM @inFechaNode.nodes('/FechaOperacion/DesasociaEmpleadoConDeduccion') X(N)
        WHERE N.value('@ValorDocumentoIdentidad[1]','VARCHAR(32)') = @inValorDocumentoIdentidad;

        SET @Fila = 1;
        SELECT @TotalFilas = COUNT(*) FROM @Desasociar;
        WHILE @Fila <= @TotalFilas
        BEGIN
            SELECT @TipoDeduccion = TipoDeduccion
            FROM @Desasociar
            WHERE Fila = @Fila;

            EXEC dbo.sp_DesasociarDeduccionEmpleadoSim
                @inValorDocumentoIdentidad,
                @TipoDeduccion,
                @inFechaOperacion,
                @tmp OUTPUT;

            IF @tmp <> 0
            BEGIN
                SET @outResultCode = @tmp;
                IF @InicioTransaccion = 1 AND @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
                RETURN;
            END;

            SET @Fila = @Fila + 1;
        END;



        /* 4. Marcas de asistencia del empleado en esta fecha */
        DECLARE @Marcas TABLE (
            Fila INT IDENTITY(1,1) PRIMARY KEY,
            HoraEntrada DATETIME2(0) NOT NULL,
            HoraSalida DATETIME2(0) NOT NULL
        );

        INSERT @Marcas (HoraEntrada, HoraSalida)
        SELECT N.value('@HoraEntrada[1]','DATETIME2(0)'),
               N.value('@HoraSalida[1]','DATETIME2(0)')
        FROM @inFechaNode.nodes('/FechaOperacion/MarcaAsistencia') X(N)
        WHERE N.value('@ValorDocumentoIdentidad[1]','VARCHAR(32)') = @inValorDocumentoIdentidad
        ORDER BY N.value('@HoraEntrada[1]','DATETIME2(0)');

        SET @Fila = 1;
        SELECT @TotalFilas = COUNT(*) FROM @Marcas;
        WHILE @Fila <= @TotalFilas
        BEGIN
            SELECT @HoraEntrada = HoraEntrada,
                   @HoraSalida = HoraSalida
            FROM @Marcas
            WHERE Fila = @Fila;

            EXEC dbo.sp_ProcesarMarcaAsistencia
                @inValorDocumentoIdentidad,
                @inFechaOperacion,
                @HoraEntrada,
                @HoraSalida,
                @tmp OUTPUT;

            IF @tmp <> 0
            BEGIN
                SET @outResultCode = @tmp;
                IF @InicioTransaccion = 1 AND @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
                RETURN;
            END;

            SET @Fila = @Fila + 1;
        END;



        /* 5. Cierre semanal por empleado: deducciones, acumulados y apertura del ciclo siguiente */
        IF dbo.fn_EsJueves(@inFechaOperacion) = 1
        BEGIN
            EXEC dbo.sp_CerrarSemanaEmpleado
                @inFechaOperacion,
                @inValorDocumentoIdentidad,
                @inEsPrimerEmpleado,
                @inEsUltimoEmpleado,
                @tmp OUTPUT;

            IF @tmp <> 0
            BEGIN
                SET @outResultCode = @tmp;
                IF @InicioTransaccion = 1 AND @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
                RETURN;
            END;
        END;



        /* 6. Eliminaciones del empleado en esta fecha */
        IF EXISTS (
            SELECT 1
            FROM @inFechaNode.nodes('/FechaOperacion/EliminarEmpleado') X(N)
            WHERE N.value('@ValorDocumentoIdentidad[1]','VARCHAR(32)') = @inValorDocumentoIdentidad
        )
        BEGIN
            EXEC dbo.sp_EliminarEmpleado
                @inValorDocumentoIdentidad,
                NULL,
                @inFechaOperacion,
                NULL,
                'SIMULACION',
                @tmp OUTPUT;

            IF @tmp <> 0
            BEGIN
                SET @outResultCode = @tmp;
                IF @InicioTransaccion = 1 AND @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
                RETURN;
            END;
        END;



        /* 7. Jornadas de la siguiente semana, después del cierre del jueves */
        DECLARE @Jornadas TABLE (
            Fila INT IDENTITY(1,1) PRIMARY KEY,
            Jornada VARCHAR(40) NOT NULL,
            InicioSemana DATE NOT NULL
        );

        INSERT @Jornadas (Jornada, InicioSemana)
        SELECT N.value('@Jornada[1]','VARCHAR(40)'),
               N.value('@InicioSemana[1]','DATE')
        FROM @inFechaNode.nodes('/FechaOperacion/AsignarJornada') X(N)
        WHERE N.value('@ValorDocumentoIdentidad[1]','VARCHAR(32)') = @inValorDocumentoIdentidad
        ORDER BY N.value('@InicioSemana[1]','DATE');

        SET @Fila = 1;
        SELECT @TotalFilas = COUNT(*) FROM @Jornadas;
        WHILE @Fila <= @TotalFilas
        BEGIN
            SELECT @Jornada = Jornada,
                   @InicioSemana = InicioSemana
            FROM @Jornadas
            WHERE Fila = @Fila;

            EXEC dbo.sp_AsignarJornadaEmpleado
                @inValorDocumentoIdentidad,
                @Jornada,
                @InicioSemana,
                @tmp OUTPUT;

            IF @tmp <> 0
            BEGIN
                SET @outResultCode = @tmp;
                IF @InicioTransaccion = 1 AND @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
                RETURN;
            END;

            SET @Fila = @Fila + 1;
        END;

        IF @InicioTransaccion = 1 COMMIT TRANSACTION;
        SET @outResultCode = 0;
    END TRY
    BEGIN CATCH
        IF @InicioTransaccion = 1 AND @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SET @outResultCode = ISNULL(NULLIF(@tmp, 0), 50008);
        THROW;
    END CATCH
END;
GO








CREATE OR ALTER PROCEDURE dbo.sp_EjecutarSimulacion
    @inXml XML,
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        DECLARE @Fechas TABLE (Fila INT IDENTITY(1,1) PRIMARY KEY, FechaOperacion DATE NOT NULL, FechaNode XML NOT NULL);
        DECLARE @FilaFecha INT = 1,
                @TotalFechas INT,
                @FechaOperacion DATE,
                @FechaNode XML,
                @tmp INT,
                @FilaEmpleado INT,
                @TotalEmpleados INT,
                @Doc VARCHAR(32),
                @FechaInicioSemana DATE,
                @IdSemana INT,
                @EsPrimerEmpleado BIT,
                @EsUltimoEmpleado BIT;

        INSERT @Fechas (FechaOperacion, FechaNode)
        SELECT F.N.value('@Fecha[1]','DATE') AS FechaOperacion, F.N.query('.') AS FechaNode
        FROM @inXml.nodes('/Operaciones/FechaOperacion') F(N)
        ORDER BY F.N.value('@Fecha[1]','DATE');

        SELECT @TotalFechas = COUNT(*) FROM @Fechas;
        WHILE @FilaFecha <= @TotalFechas
        BEGIN
            SELECT @FechaOperacion = FechaOperacion, @FechaNode = FechaNode
            FROM @Fechas WHERE Fila = @FilaFecha;

            DECLARE @Empleados TABLE (Fila INT IDENTITY(1,1) PRIMARY KEY, ValorDocumentoIdentidad VARCHAR(32) NOT NULL UNIQUE);

            INSERT @Empleados (ValorDocumentoIdentidad)
            SELECT DISTINCT N.value('@ValorDocumentoIdentidad[1]','VARCHAR(32)')
            FROM @FechaNode.nodes('/FechaOperacion/InsertarEmpleado') X(N)
            WHERE N.exist('@ValorDocumentoIdentidad') = 1;

            INSERT @Empleados (ValorDocumentoIdentidad)
            SELECT DISTINCT N.value('@ValorDocumentoIdentidad[1]','VARCHAR(32)')
            FROM @FechaNode.nodes('/FechaOperacion/AsociaEmpleadoConDeduccion') X(N)
            WHERE N.exist('@ValorDocumentoIdentidad') = 1
              AND NOT EXISTS (SELECT 1 FROM @Empleados E WHERE E.ValorDocumentoIdentidad = N.value('@ValorDocumentoIdentidad[1]','VARCHAR(32)'));

            INSERT @Empleados (ValorDocumentoIdentidad)
            SELECT DISTINCT N.value('@ValorDocumentoIdentidad[1]','VARCHAR(32)')
            FROM @FechaNode.nodes('/FechaOperacion/DesasociaEmpleadoConDeduccion') X(N)
            WHERE N.exist('@ValorDocumentoIdentidad') = 1
              AND NOT EXISTS (SELECT 1 FROM @Empleados E WHERE E.ValorDocumentoIdentidad = N.value('@ValorDocumentoIdentidad[1]','VARCHAR(32)'));

            INSERT @Empleados (ValorDocumentoIdentidad)
            SELECT DISTINCT N.value('@ValorDocumentoIdentidad[1]','VARCHAR(32)')
            FROM @FechaNode.nodes('/FechaOperacion/MarcaAsistencia') X(N)
            WHERE N.exist('@ValorDocumentoIdentidad') = 1
              AND NOT EXISTS (SELECT 1 FROM @Empleados E WHERE E.ValorDocumentoIdentidad = N.value('@ValorDocumentoIdentidad[1]','VARCHAR(32)'));

            INSERT @Empleados (ValorDocumentoIdentidad)
            SELECT DISTINCT N.value('@ValorDocumentoIdentidad[1]','VARCHAR(32)')
            FROM @FechaNode.nodes('/FechaOperacion/EliminarEmpleado') X(N)
            WHERE N.exist('@ValorDocumentoIdentidad') = 1
              AND NOT EXISTS (SELECT 1 FROM @Empleados E WHERE E.ValorDocumentoIdentidad = N.value('@ValorDocumentoIdentidad[1]','VARCHAR(32)'));

            INSERT @Empleados (ValorDocumentoIdentidad)
            SELECT DISTINCT N.value('@ValorDocumentoIdentidad[1]','VARCHAR(32)')
            FROM @FechaNode.nodes('/FechaOperacion/AsignarJornada') X(N)
            WHERE N.exist('@ValorDocumentoIdentidad') = 1
              AND NOT EXISTS (SELECT 1 FROM @Empleados E WHERE E.ValorDocumentoIdentidad = N.value('@ValorDocumentoIdentidad[1]','VARCHAR(32)'));

            IF dbo.fn_EsJueves(@FechaOperacion) = 1
            BEGIN
                SET @FechaInicioSemana = dbo.fn_ViernesDeSemana(@FechaOperacion);
                SET @IdSemana = NULL;
                SELECT @IdSemana = Id FROM dbo.SemanaPlanilla WHERE FechaInicio = @FechaInicioSemana;

                IF @IdSemana IS NOT NULL
                BEGIN
                    INSERT @Empleados (ValorDocumentoIdentidad)
                    SELECT E.ValorDocumentoIdentidad
                    FROM dbo.PlanillaSemXEmpleado PSE
                    INNER JOIN dbo.Empleado E ON E.Id = PSE.IdEmpleado
                    WHERE PSE.IdSemanaPlanilla = @IdSemana
                      AND PSE.Cerrada = 0
                      AND NOT EXISTS (SELECT 1 FROM @Empleados L WHERE L.ValorDocumentoIdentidad = E.ValorDocumentoIdentidad)
                    ORDER BY E.ValorDocumentoIdentidad;
                END;
            END;

            SET @FilaEmpleado = 1;
            SELECT @TotalEmpleados = COUNT(*) FROM @Empleados;
            WHILE @FilaEmpleado <= @TotalEmpleados
            BEGIN
                SELECT @Doc = ValorDocumentoIdentidad FROM @Empleados WHERE Fila = @FilaEmpleado;
                SET @EsPrimerEmpleado = CASE WHEN @FilaEmpleado = 1 THEN 1 ELSE 0 END;
                SET @EsUltimoEmpleado = CASE WHEN @FilaEmpleado = @TotalEmpleados THEN 1 ELSE 0 END;
                EXEC dbo.sp_ProcesarEmpleadoFechaOperacion @FechaOperacion, @FechaNode, @Doc, @EsPrimerEmpleado, @EsUltimoEmpleado, @tmp OUTPUT;
                IF @tmp <> 0
                BEGIN
                    SET @outResultCode = @tmp;
                    RETURN;
                END;
                SET @FilaEmpleado = @FilaEmpleado + 1;
            END;

            SET @FilaFecha = @FilaFecha + 1;
        END;

        SET @outResultCode = 0;
    END TRY
    BEGIN CATCH
        IF @outResultCode IS NULL OR @outResultCode = 0 SET @outResultCode = ISNULL(NULLIF(@tmp, 0), 50008);
        THROW;
    END CATCH
END;
GO








CREATE OR ALTER PROCEDURE dbo.sp_ConsultarPlanillasSemanales
    @inIdEmpleado INT,
    @inTop INT = 8,
    @inIdPostByUser INT = NULL,
    @inPostInIP VARCHAR(64) = '127.0.0.1',
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @LogJson NVARCHAR(MAX), @FechaInicio DATE, @FechaFin DATE;
    SELECT @FechaInicio = MIN(SP.FechaInicio), @FechaFin = MAX(SP.FechaFin)
    FROM dbo.PlanillaSemXEmpleado PSE
    INNER JOIN dbo.SemanaPlanilla SP ON SP.Id = PSE.IdSemanaPlanilla
    WHERE PSE.IdEmpleado = @inIdEmpleado AND (PSE.SalarioBruto > 0 OR PSE.Cerrada = 1);

    SELECT TOP (@inTop) PSE.Id AS IdPlanillaSemanal, SP.FechaInicio, SP.FechaFin, PSE.SalarioBruto, PSE.TotalDeducciones, PSE.SalarioNeto, PSE.HorasOrdinarias, PSE.HorasExtraNormales, PSE.HorasExtraDobles
    FROM dbo.PlanillaSemXEmpleado PSE
    INNER JOIN dbo.SemanaPlanilla SP ON SP.Id = PSE.IdSemanaPlanilla
    WHERE PSE.IdEmpleado = @inIdEmpleado AND (PSE.SalarioBruto > 0 OR PSE.Cerrada = 1)
    ORDER BY SP.FechaInicio DESC;

    SET @LogJson = CONCAT('{"IdEmpleado":', @inIdEmpleado, ',"FechaInicio":"', ISNULL(CONVERT(VARCHAR(10), @FechaInicio, 120), ''), '","FechaFin":"', ISNULL(CONVERT(VARCHAR(10), @FechaFin, 120), ''), '"}');
    EXEC dbo.sp_RegistrarEvento @inIdPostByUser, @inPostInIP, 'Consultar planilla semanal', @LogJson, NULL, NULL, 'OK';
    SET @outResultCode = 0;
END;
GO







CREATE OR ALTER PROCEDURE dbo.sp_ConsultarDetalleDeduccionesSemana
    @inIdPlanillaSemanal INT,
    @inIdPostByUser INT = NULL,
    @inPostInIP VARCHAR(64) = '127.0.0.1',
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @LogJson NVARCHAR(MAX), @IdEmpleado INT, @FechaInicio DATE, @FechaFin DATE;
    SELECT @IdEmpleado = PSE.IdEmpleado, @FechaInicio = SP.FechaInicio, @FechaFin = SP.FechaFin
    FROM dbo.PlanillaSemXEmpleado PSE INNER JOIN dbo.SemanaPlanilla SP ON SP.Id = PSE.IdSemanaPlanilla
    WHERE PSE.Id = @inIdPlanillaSemanal;

    SELECT TD.Nombre AS Deduccion,
           COALESCE(ED.Porcentaje, TD.Valor) AS Porcentaje,
           MP.Monto
    FROM dbo.PlanillaSemXEmpleado PSE
    INNER JOIN dbo.MovimientoPlanilla MP ON MP.IdSemanaPlanilla = PSE.IdSemanaPlanilla AND MP.IdEmpleado = PSE.IdEmpleado
    INNER JOIN dbo.TipoDeduccion TD ON TD.Id = MP.IdTipoDeduccion
    LEFT JOIN dbo.EmpleadoDeduccion ED ON ED.IdEmpleado = PSE.IdEmpleado
                                      AND ED.IdTipoDeduccion = TD.Id
                                      AND ED.FechaInicio <= MP.FechaMovimiento
                                      AND (ED.FechaFin IS NULL OR ED.FechaFin >= MP.FechaMovimiento)
    WHERE PSE.Id = @inIdPlanillaSemanal AND MP.IdTipoDeduccion IS NOT NULL
    ORDER BY TD.Nombre;

    SET @LogJson = CONCAT('{"IdEmpleado":', ISNULL(@IdEmpleado, 0), ',"IdPlanillaSemanal":', @inIdPlanillaSemanal, ',"FechaInicio":"', ISNULL(CONVERT(VARCHAR(10), @FechaInicio, 120), ''), '","FechaFin":"', ISNULL(CONVERT(VARCHAR(10), @FechaFin, 120), ''), '","Detalle":"Deducciones"}');
    EXEC dbo.sp_RegistrarEvento @inIdPostByUser, @inPostInIP, 'Consultar planilla semanal', @LogJson, NULL, NULL, 'OK';
    SET @outResultCode = 0;
END;
GO







CREATE OR ALTER PROCEDURE dbo.sp_ConsultarDetalleHorasSemana
    @inIdPlanillaSemanal INT,
    @inIdPostByUser INT = NULL,
    @inPostInIP VARCHAR(64) = '127.0.0.1',
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @LogJson NVARCHAR(MAX), @IdEmpleado INT, @FechaInicio DATE, @FechaFin DATE;
    SELECT @IdEmpleado = PSE.IdEmpleado, @FechaInicio = SP.FechaInicio, @FechaFin = SP.FechaFin
    FROM dbo.PlanillaSemXEmpleado PSE INNER JOIN dbo.SemanaPlanilla SP ON SP.Id = PSE.IdSemanaPlanilla
    WHERE PSE.Id = @inIdPlanillaSemanal;

    SELECT A.FechaOperacion, A.HoraEntrada, A.HoraSalida,
           SUM(CASE WHEN MP.IdTipoMovimiento = 1 THEN ISNULL(MP.CantidadHoras,0) ELSE 0 END) HorasOrdinarias,
           SUM(CASE WHEN MP.IdTipoMovimiento = 1 THEN MP.Monto ELSE 0 END) MontoOrdinario,
           SUM(CASE WHEN MP.IdTipoMovimiento = 2 THEN ISNULL(MP.CantidadHoras,0) ELSE 0 END) HorasExtraNormales,
           SUM(CASE WHEN MP.IdTipoMovimiento = 2 THEN MP.Monto ELSE 0 END) MontoExtraNormal,
           SUM(CASE WHEN MP.IdTipoMovimiento = 3 THEN ISNULL(MP.CantidadHoras,0) ELSE 0 END) HorasExtraDobles,
           SUM(CASE WHEN MP.IdTipoMovimiento = 3 THEN MP.Monto ELSE 0 END) MontoExtraDoble
    FROM dbo.PlanillaSemXEmpleado PSE
    INNER JOIN dbo.Asistencia A ON A.IdSemanaPlanilla = PSE.IdSemanaPlanilla AND A.IdEmpleado = PSE.IdEmpleado
    LEFT JOIN dbo.MovimientoPlanilla MP ON MP.IdAsistencia = A.Id
    WHERE PSE.Id = @inIdPlanillaSemanal
    GROUP BY A.FechaOperacion, A.HoraEntrada, A.HoraSalida
    ORDER BY A.HoraEntrada;

    SET @LogJson = CONCAT('{"IdEmpleado":', ISNULL(@IdEmpleado, 0), ',"IdPlanillaSemanal":', @inIdPlanillaSemanal, ',"FechaInicio":"', ISNULL(CONVERT(VARCHAR(10), @FechaInicio, 120), ''), '","FechaFin":"', ISNULL(CONVERT(VARCHAR(10), @FechaFin, 120), ''), '","Detalle":"Horas"}');
    EXEC dbo.sp_RegistrarEvento @inIdPostByUser, @inPostInIP, 'Consultar planilla semanal', @LogJson, NULL, NULL, 'OK';
    SET @outResultCode = 0;
END;
GO







CREATE OR ALTER PROCEDURE dbo.sp_ConsultarPlanillasMensuales
    @inIdEmpleado INT,
    @inTop INT = 6,
    @inIdPostByUser INT = NULL,
    @inPostInIP VARCHAR(64) = '127.0.0.1',
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @LogJson NVARCHAR(MAX), @FechaInicio DATE, @FechaFin DATE;
    SELECT @FechaInicio = MIN(MP.FechaInicio), @FechaFin = MAX(MP.FechaFin)
    FROM dbo.PlanillaMesXEmpleado PME
    INNER JOIN dbo.MesPlanilla MP ON MP.Id = PME.IdMesPlanilla
    WHERE PME.IdEmpleado = @inIdEmpleado AND (PME.SalarioBruto > 0 OR PME.TotalDeducciones > 0);

    SELECT TOP (@inTop) PME.Id AS IdPlanillaMensual, MP.FechaInicio, MP.FechaFin, PME.SalarioBruto, PME.TotalDeducciones, PME.SalarioNeto
    FROM dbo.PlanillaMesXEmpleado PME
    INNER JOIN dbo.MesPlanilla MP ON MP.Id = PME.IdMesPlanilla
    WHERE PME.IdEmpleado = @inIdEmpleado AND (PME.SalarioBruto > 0 OR PME.TotalDeducciones > 0)
    ORDER BY MP.FechaInicio DESC;

    SET @LogJson = CONCAT('{"IdEmpleado":', @inIdEmpleado, ',"FechaInicio":"', ISNULL(CONVERT(VARCHAR(10), @FechaInicio, 120), ''), '","FechaFin":"', ISNULL(CONVERT(VARCHAR(10), @FechaFin, 120), ''), '"}');
    EXEC dbo.sp_RegistrarEvento @inIdPostByUser, @inPostInIP, 'Consultar planilla mensual', @LogJson, NULL, NULL, 'OK';
    SET @outResultCode = 0;
END;
GO







CREATE OR ALTER PROCEDURE dbo.sp_ConsultarDetalleDeduccionesMes
    @inIdPlanillaMensual INT,
    @inIdPostByUser INT = NULL,
    @inPostInIP VARCHAR(64) = '127.0.0.1',
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @LogJson NVARCHAR(MAX), @IdEmpleado INT, @FechaInicio DATE, @FechaFin DATE;
    SELECT @IdEmpleado = PME.IdEmpleado, @FechaInicio = MP.FechaInicio, @FechaFin = MP.FechaFin
    FROM dbo.PlanillaMesXEmpleado PME INNER JOIN dbo.MesPlanilla MP ON MP.Id = PME.IdMesPlanilla
    WHERE PME.Id = @inIdPlanillaMensual;

    SELECT TD.Nombre AS Deduccion, DEM.PorcentajeAplicado AS Porcentaje, DEM.Monto
    FROM dbo.PlanillaMesXEmpleado PME
    INNER JOIN dbo.DeduccionXEmpleadoXMes DEM ON DEM.IdMesPlanilla = PME.IdMesPlanilla AND DEM.IdEmpleado = PME.IdEmpleado
    INNER JOIN dbo.TipoDeduccion TD ON TD.Id = DEM.IdTipoDeduccion
    WHERE PME.Id = @inIdPlanillaMensual
    ORDER BY TD.Nombre;

    SET @LogJson = CONCAT('{"IdEmpleado":', ISNULL(@IdEmpleado, 0), ',"IdPlanillaMensual":', @inIdPlanillaMensual, ',"FechaInicio":"', ISNULL(CONVERT(VARCHAR(10), @FechaInicio, 120), ''), '","FechaFin":"', ISNULL(CONVERT(VARCHAR(10), @FechaFin, 120), ''), '","Detalle":"Deducciones"}');
    EXEC dbo.sp_RegistrarEvento @inIdPostByUser, @inPostInIP, 'Consultar planilla mensual', @LogJson, NULL, NULL, 'OK';
    SET @outResultCode = 0;
END;
GO


IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = N'developer_proyecto3')
BEGIN
    CREATE LOGIN developer_proyecto3 WITH PASSWORD = 'Proyecto3_2026!', CHECK_POLICY = OFF;
END;
GO
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'developer_proyecto3')
BEGIN
    CREATE USER developer_proyecto3 FOR LOGIN developer_proyecto3;
END;
GO
GRANT EXECUTE TO developer_proyecto3;
GRANT SELECT ON SCHEMA::dbo TO developer_proyecto3;
GO
