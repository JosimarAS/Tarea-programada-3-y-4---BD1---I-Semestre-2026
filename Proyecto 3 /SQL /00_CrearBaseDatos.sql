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
    BEGIN TRY
        BEGIN TRANSACTION;

        MERGE dbo.TipoUsuario AS T
        USING (SELECT N.value('@Id','INT') Id, N.value('@Nombre','VARCHAR(32)') Nombre FROM @inXml.nodes('/Catalogo/TiposUsuario/TipoUsuario') X(N)) AS S
        ON T.Id = S.Id
        WHEN MATCHED THEN UPDATE SET Nombre = S.Nombre
        WHEN NOT MATCHED THEN INSERT (Id, Nombre) VALUES (S.Id, S.Nombre);

        MERGE dbo.TipoJornada AS T
        USING (SELECT N.value('@Id','INT') Id, N.value('@Nombre','VARCHAR(40)') Nombre, N.value('@HoraInicio','TIME(0)') HoraInicio, N.value('@HoraFin','TIME(0)') HoraFin FROM @inXml.nodes('/Catalogo/TiposDeJornada/TipoDeJornada') X(N)) AS S
        ON T.Id = S.Id
        WHEN MATCHED THEN UPDATE SET Nombre = S.Nombre, HoraInicio = S.HoraInicio, HoraFin = S.HoraFin
        WHEN NOT MATCHED THEN INSERT (Id, Nombre, HoraInicio, HoraFin) VALUES (S.Id, S.Nombre, S.HoraInicio, S.HoraFin);

        MERGE dbo.Puesto AS T
        USING (SELECT N.value('@Nombre','VARCHAR(80)') Nombre, N.value('@SalarioXHora','DECIMAL(18,2)') SalarioXHora FROM @inXml.nodes('/Catalogo/Puestos/Puesto') X(N)) AS S
        ON T.Nombre = S.Nombre
        WHEN MATCHED THEN UPDATE SET SalarioXHora = S.SalarioXHora
        WHEN NOT MATCHED THEN INSERT (Nombre, SalarioXHora) VALUES (S.Nombre, S.SalarioXHora);

        ;WITH SalarioPorJornada AS (
            SELECT P.Id AS IdPuesto,
                   TJ.Id AS IdTipoJornada,
                   CASE
                       WHEN TJ.Nombre = 'Diurno' AND N.exist('@SalarioDiurno') = 1 THEN N.value('@SalarioDiurno[1]','DECIMAL(18,2)')
                       WHEN TJ.Nombre = 'Vespertino' AND N.exist('@SalarioVespertino') = 1 THEN N.value('@SalarioVespertino[1]','DECIMAL(18,2)')
                       WHEN TJ.Nombre = 'Nocturno' AND N.exist('@SalarioNocturno') = 1 THEN N.value('@SalarioNocturno[1]','DECIMAL(18,2)')
                       ELSE N.value('@SalarioXHora[1]','DECIMAL(18,2)')
                   END AS SalarioXHora
            FROM @inXml.nodes('/Catalogo/Puestos/Puesto') X(N)
            INNER JOIN dbo.Puesto P ON P.Nombre = N.value('@Nombre[1]','VARCHAR(80)')
            CROSS JOIN dbo.TipoJornada TJ
        )
        MERGE dbo.PuestoJornadaSalario AS T
        USING SalarioPorJornada AS S
        ON T.IdPuesto = S.IdPuesto AND T.IdTipoJornada = S.IdTipoJornada
        WHEN MATCHED THEN UPDATE SET SalarioXHora = S.SalarioXHora
        WHEN NOT MATCHED THEN INSERT (IdPuesto, IdTipoJornada, SalarioXHora) VALUES (S.IdPuesto, S.IdTipoJornada, S.SalarioXHora);

        MERGE dbo.Feriado AS T
        USING (SELECT N.value('@Id','INT') Id, N.value('@Nombre','VARCHAR(100)') Nombre, N.value('@Fecha','DATE') Fecha FROM @inXml.nodes('/Catalogo/Feriados/Feriado') X(N)) AS S
        ON T.Id = S.Id
        WHEN MATCHED THEN UPDATE SET Nombre = S.Nombre, Fecha = S.Fecha
        WHEN NOT MATCHED THEN INSERT (Id, Nombre, Fecha) VALUES (S.Id, S.Nombre, S.Fecha);

        MERGE dbo.TipoMovimiento AS T
        USING (SELECT N.value('@Id','INT') Id, N.value('@Nombre','VARCHAR(100)') Nombre, N.value('@Accion','CHAR(1)') Accion FROM @inXml.nodes('/Catalogo/TiposDeMovimiento/TipoDeMovimiento') X(N)) AS S
        ON T.Id = S.Id
        WHEN MATCHED THEN UPDATE SET Nombre = S.Nombre, Accion = S.Accion
        WHEN NOT MATCHED THEN INSERT (Id, Nombre, Accion) VALUES (S.Id, S.Nombre, S.Accion);

        MERGE dbo.TipoDeduccion AS T
        USING (
            SELECT N.value('@Id','INT') Id,
                   N.value('@Nombre','VARCHAR(100)') Nombre,
                   CASE WHEN LOWER(N.value('@Obligatorio','VARCHAR(10)')) IN ('si','sí','1','true') THEN CONVERT(BIT,1) ELSE CONVERT(BIT,0) END Obligatorio,
                   CASE WHEN LOWER(N.value('@Porcentual','VARCHAR(10)')) IN ('si','sí','1','true') THEN CONVERT(BIT,1) ELSE CONVERT(BIT,0) END Porcentual,
                   N.value('@Valor','DECIMAL(18,4)') Valor,
                   N.value('@IdTipoMov','INT') IdTipoMovimiento
            FROM @inXml.nodes('/Catalogo/TiposDeDeduccion/TipoDeDeduccion') X(N)
        ) AS S
        ON T.Id = S.Id
        WHEN MATCHED THEN UPDATE SET Nombre = S.Nombre, Obligatorio = S.Obligatorio, Porcentual = S.Porcentual, Valor = S.Valor, IdTipoMovimiento = S.IdTipoMovimiento
        WHEN NOT MATCHED THEN INSERT (Id, Nombre, Obligatorio, Porcentual, Valor, IdTipoMovimiento) VALUES (S.Id, S.Nombre, S.Obligatorio, S.Porcentual, S.Valor, S.IdTipoMovimiento);

        MERGE dbo.TipoEvento AS T
        USING (SELECT N.value('@Id','INT') Id, N.value('@Nombre','VARCHAR(100)') Nombre FROM @inXml.nodes('/Catalogo/TiposDeEvento/TipoEvento') X(N)) AS S
        ON T.Id = S.Id
        WHEN MATCHED THEN UPDATE SET Nombre = S.Nombre
        WHEN NOT MATCHED THEN INSERT (Id, Nombre) VALUES (S.Id, S.Nombre);

        MERGE dbo.Usuario AS T
        USING (SELECT N.value('@Username','VARCHAR(64)') Username, N.value('@Password','VARCHAR(128)') Password, N.value('@TipoUsuario','INT') IdTipoUsuario FROM @inXml.nodes('/Catalogo/Usuarios/Usuario') X(N)) AS S
        ON T.Username = S.Username
        WHEN MATCHED THEN UPDATE SET Password = S.Password, IdTipoUsuario = S.IdTipoUsuario, Activo = 1
        WHEN NOT MATCHED THEN INSERT (Username, Password, IdTipoUsuario, IdEmpleado, Activo) VALUES (S.Username, S.Password, S.IdTipoUsuario, NULL, 1);

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
    DECLARE @LogJson NVARCHAR(MAX), @Despues NVARCHAR(MAX);
    SET @outIdEmpleado = NULL;
    IF EXISTS (SELECT 1 FROM dbo.Empleado WHERE ValorDocumentoIdentidad = @inValorDocumentoIdentidad)
    BEGIN SET @outResultCode = 50004; RETURN; END;
    IF NOT EXISTS (SELECT 1 FROM dbo.Puesto WHERE Id = @inIdPuesto)
    BEGIN SET @outResultCode = 50006; RETURN; END;
    IF NOT EXISTS (SELECT 1 FROM dbo.TipoUsuario WHERE Id = @inIdTipoUsuario)
    BEGIN SET @outResultCode = 50012; RETURN; END;

    BEGIN TRY
        BEGIN TRANSACTION;
        INSERT dbo.Empleado (ValorDocumentoIdentidad, Nombre, IdPuesto, CuentaBancaria, FechaContratacion)
        VALUES (@inValorDocumentoIdentidad, @inNombre, @inIdPuesto, @inCuentaBancaria, @inFechaContratacion);
        SET @outIdEmpleado = SCOPE_IDENTITY();

        INSERT dbo.Usuario (Username, Password, IdTipoUsuario, IdEmpleado, Activo)
        VALUES (@inUsername, @inPassword, @inIdTipoUsuario, CASE WHEN @inIdTipoUsuario = 0 THEN @outIdEmpleado ELSE NULL END, 1);

        SET @LogJson = CONCAT('{"Documento":"', @inValorDocumentoIdentidad, '","Nombre":"', @inNombre, '"}');
        SELECT @Despues = (SELECT E.Id, E.ValorDocumentoIdentidad, E.Nombre, E.IdPuesto, E.CuentaBancaria, E.FechaContratacion FROM dbo.Empleado E WHERE E.Id = @outIdEmpleado FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);
        EXEC dbo.sp_RegistrarEvento @inIdPostByUser, @inPostInIP, 'Insertar empleado', @LogJson, NULL, @Despues, 'OK';
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
    DECLARE @Antes NVARCHAR(MAX), @Despues NVARCHAR(MAX), @LogJson NVARCHAR(MAX);
    IF @inIdEmpleado IS NULL
        SELECT @inIdEmpleado = Id FROM dbo.Empleado WHERE ValorDocumentoIdentidad = @inValorDocumentoIdentidad;
    IF @inIdEmpleado IS NULL BEGIN SET @outResultCode = 50007; RETURN; END;

    SELECT @Antes = (SELECT * FROM dbo.Empleado WHERE Id = @inIdEmpleado FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);
    BEGIN TRY
        BEGIN TRANSACTION;
        UPDATE dbo.Empleado SET Activo = 0, FechaSalida = ISNULL(@inFechaSalida, CAST(SYSDATETIME() AS DATE)) WHERE Id = @inIdEmpleado;
        UPDATE dbo.Usuario SET Activo = 0 WHERE IdEmpleado = @inIdEmpleado;
        SET @LogJson = CONCAT('{"IdEmpleado":', @inIdEmpleado, '}');
        SELECT @Despues = (SELECT * FROM dbo.Empleado WHERE Id = @inIdEmpleado FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);
        EXEC dbo.sp_RegistrarEvento @inIdPostByUser, @inPostInIP, 'Eliminar empleado', @LogJson, @Antes, @Despues, 'OK';
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
    DECLARE @LogJson NVARCHAR(MAX);
    IF NOT EXISTS (SELECT 1 FROM dbo.Empleado WHERE Id = @inIdEmpleado) BEGIN SET @outResultCode = 50007; RETURN; END;
    IF NOT EXISTS (SELECT 1 FROM dbo.TipoDeduccion WHERE Id = @inIdTipoDeduccion AND Obligatorio = 0) BEGIN SET @outResultCode = 50009; RETURN; END;

    DECLARE @Porcentual BIT, @ValorDefault DECIMAL(18,4);
    SELECT @Porcentual = Porcentual, @ValorDefault = Valor FROM dbo.TipoDeduccion WHERE Id = @inIdTipoDeduccion;

    BEGIN TRY
        BEGIN TRANSACTION;
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
    DECLARE @IdEmpleado INT, @IdTipoDeduccion INT, @FechaFin DATE, @LogJson NVARCHAR(MAX);
    SELECT @IdEmpleado = Id FROM dbo.Empleado WHERE ValorDocumentoIdentidad = @inValorDocumentoIdentidad;
    SELECT @IdTipoDeduccion = Id FROM dbo.TipoDeduccion WHERE Nombre = @inTipoDeduccion AND Obligatorio = 0;
    IF @IdEmpleado IS NULL BEGIN SET @outResultCode = 50007; RETURN; END;
    IF @IdTipoDeduccion IS NULL BEGIN SET @outResultCode = 50009; RETURN; END;
    SET @FechaFin = DATEADD(DAY, -1, dbo.fn_SiguienteViernes(@inFechaOperacion));
    BEGIN TRY
        BEGIN TRANSACTION;
        UPDATE dbo.EmpleadoDeduccion SET Activo = 0, FechaFin = @FechaFin
        WHERE IdEmpleado = @IdEmpleado AND IdTipoDeduccion = @IdTipoDeduccion AND Activo = 1;
        SET @LogJson = CONCAT('{"IdEmpleado":', @IdEmpleado, ',"IdTipoDeduccion":', @IdTipoDeduccion, '}');
        EXEC dbo.sp_RegistrarEvento NULL, 'SIMULACION', 'Desasociar deduccion', @LogJson, NULL, NULL, 'OK';
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

CREATE OR ALTER PROCEDURE dbo.sp_AsignarJornadaEmpleado
    @inValorDocumentoIdentidad VARCHAR(32),
    @inJornada VARCHAR(40),
    @inInicioSemana DATE,
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @IdEmpleado INT, @IdTipoJornada INT, @IdSemana INT, @FechaSalida DATE, @tmpCode INT, @LogJson NVARCHAR(MAX);
    SELECT @IdEmpleado = Id, @FechaSalida = FechaSalida FROM dbo.Empleado WHERE ValorDocumentoIdentidad = @inValorDocumentoIdentidad;
    SELECT @IdTipoJornada = Id FROM dbo.TipoJornada WHERE Nombre = @inJornada;
    IF @IdEmpleado IS NULL BEGIN SET @outResultCode = 50007; RETURN; END;
    IF @IdTipoJornada IS NULL BEGIN SET @outResultCode = 50010; RETURN; END;

    BEGIN TRY
        BEGIN TRANSACTION;
        EXEC dbo.sp_AbrirSemanaSiNoExiste @inInicioSemana, @IdSemana OUTPUT, @tmpCode OUTPUT;
        IF @tmpCode <> 0
        BEGIN ROLLBACK TRANSACTION; SET @outResultCode = @tmpCode; RETURN; END;

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
            @TotalDevengado DECIMAL(18,2), @tmpCode INT, @LogJson NVARCHAR(MAX);

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
        BEGIN TRANSACTION;
        EXEC dbo.sp_AbrirSemanaSiNoExiste @FechaInicioSemana, @IdSemana OUTPUT, @tmpCode OUTPUT;
        IF @tmpCode <> 0 BEGIN SET @outResultCode = @tmpCode; ROLLBACK TRANSACTION; RETURN; END;

        SELECT @IdMes = IdMesPlanilla FROM dbo.SemanaPlanilla WHERE Id = @IdSemana;

        SET @HorasTrabajadas = FLOOR(CAST(DATEDIFF(MINUTE, @inHoraEntrada, @inHoraSalida) AS DECIMAL(9,2)) / 60.0);
        SET @HorasOrd = CASE WHEN @HorasTrabajadas >= 8 THEN 8 ELSE @HorasTrabajadas END;
        SET @HorasExtra = CASE WHEN @inHoraSalida > @DtFinJornada THEN FLOOR(CAST(DATEDIFF(MINUTE, @DtFinJornada, @inHoraSalida) AS DECIMAL(9,2)) / 60.0) ELSE 0 END;
        IF @HorasExtra < 0 SET @HorasExtra = 0;
        SET @HorasExtraDoble = CASE WHEN @HorasExtra > 0 AND (dbo.fn_EsDomingo(@inFechaOperacion) = 1 OR dbo.fn_EsFeriado(@inFechaOperacion) = 1) THEN @HorasExtra ELSE 0 END;
        SET @HorasExtraNormal = CASE WHEN @HorasExtra > 0 AND @HorasExtraDoble = 0 THEN @HorasExtra ELSE 0 END;

        SET @MontoOrd = ROUND(@HorasOrd * @SalarioXHora, 2);
        SET @MontoExtraNormal = ROUND(@HorasExtraNormal * @SalarioXHora * 1.5, 2);
        SET @MontoExtraDoble = ROUND(@HorasExtraDoble * @SalarioXHora * 2.0, 2);
        SET @TotalDevengado = @MontoOrd + @MontoExtraNormal + @MontoExtraDoble;

        INSERT dbo.Asistencia (IdEmpleado, IdSemanaPlanilla, FechaOperacion, HoraEntrada, HoraSalida)
        VALUES (@IdEmpleado, @IdSemana, @inFechaOperacion, @inHoraEntrada, @inHoraSalida);
        SET @IdAsistencia = SCOPE_IDENTITY();

        IF @HorasOrd > 0
            INSERT dbo.MovimientoPlanilla (IdEmpleado, IdSemanaPlanilla, IdMesPlanilla, IdAsistencia, IdTipoMovimiento, FechaMovimiento, CantidadHoras, Monto, Detalle)
            VALUES (@IdEmpleado, @IdSemana, @IdMes, @IdAsistencia, 1, @inFechaOperacion, @HorasOrd, @MontoOrd, 'Horas ordinarias');
        IF @HorasExtraNormal > 0
            INSERT dbo.MovimientoPlanilla (IdEmpleado, IdSemanaPlanilla, IdMesPlanilla, IdAsistencia, IdTipoMovimiento, FechaMovimiento, CantidadHoras, Monto, Detalle)
            VALUES (@IdEmpleado, @IdSemana, @IdMes, @IdAsistencia, 2, @inFechaOperacion, @HorasExtraNormal, @MontoExtraNormal, 'Horas extra normales');
        IF @HorasExtraDoble > 0
            INSERT dbo.MovimientoPlanilla (IdEmpleado, IdSemanaPlanilla, IdMesPlanilla, IdAsistencia, IdTipoMovimiento, FechaMovimiento, CantidadHoras, Monto, Detalle)
            VALUES (@IdEmpleado, @IdSemana, @IdMes, @IdAsistencia, 3, @inFechaOperacion, @HorasExtraDoble, @MontoExtraDoble, 'Horas extra dobles');

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


CREATE OR ALTER PROCEDURE dbo.sp_CerrarMesSiCorresponde
    @inFechaOperacion DATE,
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @IdMesPlanilla INT, @LogJson NVARCHAR(MAX);

    SELECT @IdMesPlanilla = Id
    FROM dbo.MesPlanilla
    WHERE FechaFin = @inFechaOperacion AND Cerrado = 0;

    IF @IdMesPlanilla IS NULL
    BEGIN
        SET @outResultCode = 0;
        RETURN;
    END;

    BEGIN TRY
        BEGIN TRANSACTION;

        MERGE dbo.TransferenciaDeduccionMes AS T
        USING (
            SELECT IdMesPlanilla, IdTipoDeduccion, SUM(Monto) AS MontoTotal
            FROM dbo.DeduccionXEmpleadoXMes
            WHERE IdMesPlanilla = @IdMesPlanilla
            GROUP BY IdMesPlanilla, IdTipoDeduccion
        ) AS S
        ON T.IdMesPlanilla = S.IdMesPlanilla AND T.IdTipoDeduccion = S.IdTipoDeduccion
        WHEN MATCHED THEN UPDATE SET MontoTotal = S.MontoTotal, FechaTransferencia = @inFechaOperacion
        WHEN NOT MATCHED THEN INSERT (IdMesPlanilla, IdTipoDeduccion, MontoTotal, FechaTransferencia)
             VALUES (S.IdMesPlanilla, S.IdTipoDeduccion, S.MontoTotal, @inFechaOperacion);

        UPDATE dbo.MesPlanilla
        SET Cerrado = 1
        WHERE Id = @IdMesPlanilla;

        SET @LogJson = CONCAT('{"IdMesPlanilla":', @IdMesPlanilla, ',"FechaCierre":"', CONVERT(VARCHAR(10), @inFechaOperacion, 120), '"}');
        EXEC dbo.sp_RegistrarEvento NULL, 'SIMULACION', 'Cierre mensual', @LogJson, NULL, NULL, 'OK';

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

CREATE OR ALTER PROCEDURE dbo.sp_CerrarSemana
    @inFechaOperacion DATE,
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @FechaInicioSemana DATE = dbo.fn_ViernesDeSemana(@inFechaOperacion), @IdSemana INT, @IdMes INT, @IdEmpleado INT, @Bruto DECIMAL(18,2), @CantidadSemanas INT;
    DECLARE @IdNuevaSemana INT, @tmp INT, @FechaInicioNuevaSemana DATE, @LogJson NVARCHAR(MAX);
    SELECT @IdSemana = SP.Id, @IdMes = SP.IdMesPlanilla
    FROM dbo.SemanaPlanilla SP WHERE SP.FechaInicio = @FechaInicioSemana;
    IF @IdSemana IS NULL BEGIN SET @outResultCode = 0; RETURN; END;
    SELECT @CantidadSemanas = CantidadSemanas FROM dbo.MesPlanilla WHERE Id = @IdMes;

    DECLARE curEmp CURSOR LOCAL FAST_FORWARD FOR
        SELECT IdEmpleado, SalarioBruto FROM dbo.PlanillaSemXEmpleado WHERE IdSemanaPlanilla = @IdSemana AND Cerrada = 0;
    OPEN curEmp;
    FETCH NEXT FROM curEmp INTO @IdEmpleado, @Bruto;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        BEGIN TRY
            BEGIN TRANSACTION;
            DECLARE @IdTipoDeduccion INT, @IdTipoMovimiento INT, @Porcentual BIT, @Porcentaje DECIMAL(18,4), @MontoFijo DECIMAL(18,2), @MontoDeduccion DECIMAL(18,2), @NombreDeduccion VARCHAR(100);
            DECLARE curDed CURSOR LOCAL FAST_FORWARD FOR
                SELECT TD.Id, TD.IdTipoMovimiento, TD.Porcentual, ISNULL(ED.Porcentaje, TD.Valor), ED.MontoFijo, TD.Nombre
                FROM dbo.EmpleadoDeduccion ED
                INNER JOIN dbo.TipoDeduccion TD ON TD.Id = ED.IdTipoDeduccion
                WHERE ED.IdEmpleado = @IdEmpleado
                  AND ED.FechaInicio <= @inFechaOperacion
                  AND (ED.FechaFin IS NULL OR ED.FechaFin >= @FechaInicioSemana);
            OPEN curDed;
            FETCH NEXT FROM curDed INTO @IdTipoDeduccion, @IdTipoMovimiento, @Porcentual, @Porcentaje, @MontoFijo, @NombreDeduccion;
            WHILE @@FETCH_STATUS = 0
            BEGIN
                SET @MontoDeduccion = CASE WHEN @Porcentual = 1 THEN ROUND(@Bruto * @Porcentaje, 2) ELSE ROUND(ISNULL(@MontoFijo, 0) / @CantidadSemanas, 2) END;
                IF @MontoDeduccion > 0
                BEGIN
                    INSERT dbo.MovimientoPlanilla (IdEmpleado, IdSemanaPlanilla, IdMesPlanilla, IdTipoMovimiento, IdTipoDeduccion, FechaMovimiento, CantidadHoras, Monto, Detalle)
                    VALUES (@IdEmpleado, @IdSemana, @IdMes, @IdTipoMovimiento, @IdTipoDeduccion, @inFechaOperacion, NULL, @MontoDeduccion, @NombreDeduccion);

                    UPDATE dbo.PlanillaSemXEmpleado SET TotalDeducciones = TotalDeducciones + @MontoDeduccion WHERE IdSemanaPlanilla = @IdSemana AND IdEmpleado = @IdEmpleado;
                    UPDATE dbo.PlanillaMesXEmpleado SET TotalDeducciones = TotalDeducciones + @MontoDeduccion WHERE IdMesPlanilla = @IdMes AND IdEmpleado = @IdEmpleado;

                    MERGE dbo.DeduccionXEmpleadoXMes AS T
                    USING (SELECT @IdMes IdMesPlanilla, @IdEmpleado IdEmpleado, @IdTipoDeduccion IdTipoDeduccion) AS S
                    ON T.IdMesPlanilla = S.IdMesPlanilla AND T.IdEmpleado = S.IdEmpleado AND T.IdTipoDeduccion = S.IdTipoDeduccion
                    WHEN MATCHED THEN UPDATE SET Monto = T.Monto + @MontoDeduccion, PorcentajeAplicado = CASE WHEN @Porcentual = 1 THEN @Porcentaje ELSE T.PorcentajeAplicado END
                    WHEN NOT MATCHED THEN INSERT (IdMesPlanilla, IdEmpleado, IdTipoDeduccion, PorcentajeAplicado, Monto) VALUES (@IdMes, @IdEmpleado, @IdTipoDeduccion, CASE WHEN @Porcentual = 1 THEN @Porcentaje ELSE NULL END, @MontoDeduccion);
                END;
                FETCH NEXT FROM curDed INTO @IdTipoDeduccion, @IdTipoMovimiento, @Porcentual, @Porcentaje, @MontoFijo, @NombreDeduccion;
            END;
            CLOSE curDed; DEALLOCATE curDed;
            UPDATE dbo.PlanillaSemXEmpleado SET Cerrada = 1 WHERE IdSemanaPlanilla = @IdSemana AND IdEmpleado = @IdEmpleado;
            SET @LogJson = CONCAT('{"IdEmpleado":', @IdEmpleado, ',"IdSemanaPlanilla":', @IdSemana, ',"FechaInicio":"', CONVERT(VARCHAR(10), @FechaInicioSemana, 120), '","FechaFin":"', CONVERT(VARCHAR(10), @inFechaOperacion, 120), '"}');
            EXEC dbo.sp_RegistrarEvento NULL, 'SIMULACION', 'Cierre semanal', @LogJson, NULL, NULL, 'OK';
            COMMIT TRANSACTION;
        END TRY
        BEGIN CATCH
            IF CURSOR_STATUS('local','curDed') >= 0 CLOSE curDed;
            IF CURSOR_STATUS('local','curDed') > -3 DEALLOCATE curDed;
            IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
            CLOSE curEmp; DEALLOCATE curEmp;
            SET @outResultCode = 50008;
            THROW;
        END CATCH;
        FETCH NEXT FROM curEmp INTO @IdEmpleado, @Bruto;
    END;
    CLOSE curEmp; DEALLOCATE curEmp;

    BEGIN TRY
        BEGIN TRANSACTION;
        UPDATE dbo.SemanaPlanilla SET Cerrada = 1 WHERE Id = @IdSemana;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SET @outResultCode = 50008;
        THROW;
    END CATCH;

    SET @FechaInicioNuevaSemana = DATEADD(DAY, 1, @inFechaOperacion);
    EXEC dbo.sp_AbrirSemanaSiNoExiste @FechaInicioNuevaSemana, @IdNuevaSemana OUTPUT, @tmp OUTPUT;
    IF @tmp <> 0 BEGIN SET @outResultCode = @tmp; RETURN; END;

    EXEC dbo.sp_CerrarMesSiCorresponde @inFechaOperacion, @tmp OUTPUT;
    IF @tmp <> 0 BEGIN SET @outResultCode = @tmp; RETURN; END;

    SET @outResultCode = 0;
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
        DECLARE @FechaOperacion DATE, @FechaNode XML, @tmp INT;
        DECLARE curFecha CURSOR LOCAL FAST_FORWARD FOR
            SELECT F.N.value('@Fecha','DATE') Fecha, F.N.query('.') FechaNode
            FROM @inXml.nodes('/Operaciones/FechaOperacion') F(N)
            ORDER BY F.N.value('@Fecha','DATE');
        OPEN curFecha;
        FETCH NEXT FROM curFecha INTO @FechaOperacion, @FechaNode;
        WHILE @@FETCH_STATUS = 0
        BEGIN
            BEGIN TRY
                BEGIN TRANSACTION;

                DECLARE @Doc VARCHAR(32), @Nombre VARCHAR(128), @Puesto VARCHAR(80), @Cuenta VARCHAR(40), @Username VARCHAR(64), @Password VARCHAR(128), @TipoUsuario INT, @FechaContratacion DATE;
                DECLARE curIns CURSOR LOCAL FAST_FORWARD FOR
                    SELECT N.value('@ValorDocumentoIdentidad','VARCHAR(32)'), N.value('@Nombre','VARCHAR(128)'), N.value('@Puesto','VARCHAR(80)'), N.value('@CuentaBancaria','VARCHAR(40)'), N.value('@Username','VARCHAR(64)'), N.value('@Password','VARCHAR(128)'), N.value('@TipoUsuario','INT'), N.value('@FechaContratacion','DATE')
                    FROM @FechaNode.nodes('/FechaOperacion/InsertarEmpleado') X(N);
                OPEN curIns; FETCH NEXT FROM curIns INTO @Doc,@Nombre,@Puesto,@Cuenta,@Username,@Password,@TipoUsuario,@FechaContratacion;
                WHILE @@FETCH_STATUS = 0
                BEGIN
                    EXEC dbo.sp_InsertarEmpleadoSim @Doc,@Nombre,@Puesto,@Cuenta,@Username,@Password,@TipoUsuario,@FechaContratacion,@tmp OUTPUT;
                    IF @tmp <> 0 THROW 51000, 'Error procesando InsertarEmpleado.', 1;
                    FETCH NEXT FROM curIns INTO @Doc,@Nombre,@Puesto,@Cuenta,@Username,@Password,@TipoUsuario,@FechaContratacion;
                END;
                CLOSE curIns; DEALLOCATE curIns;

                DECLARE @TipoDeduccion VARCHAR(100), @MontoFijo DECIMAL(18,2);
                DECLARE curAsoc CURSOR LOCAL FAST_FORWARD FOR SELECT N.value('@ValorDocumentoIdentidad','VARCHAR(32)'), N.value('@TipoDeduccion','VARCHAR(100)'), N.value('@MontoFijo','DECIMAL(18,2)') FROM @FechaNode.nodes('/FechaOperacion/AsociaEmpleadoConDeduccion') X(N);
                OPEN curAsoc; FETCH NEXT FROM curAsoc INTO @Doc,@TipoDeduccion,@MontoFijo;
                WHILE @@FETCH_STATUS = 0
                BEGIN
                    EXEC dbo.sp_AsociarDeduccionEmpleadoSim @Doc,@TipoDeduccion,@MontoFijo,@FechaOperacion,@tmp OUTPUT;
                    IF @tmp <> 0 THROW 51002, 'Error procesando AsociaEmpleadoConDeduccion.', 1;
                    FETCH NEXT FROM curAsoc INTO @Doc,@TipoDeduccion,@MontoFijo;
                END;
                CLOSE curAsoc; DEALLOCATE curAsoc;

                DECLARE curDes CURSOR LOCAL FAST_FORWARD FOR SELECT N.value('@ValorDocumentoIdentidad','VARCHAR(32)'), N.value('@TipoDeduccion','VARCHAR(100)') FROM @FechaNode.nodes('/FechaOperacion/DesasociaEmpleadoConDeduccion') X(N);
                OPEN curDes; FETCH NEXT FROM curDes INTO @Doc,@TipoDeduccion;
                WHILE @@FETCH_STATUS = 0
                BEGIN
                    EXEC dbo.sp_DesasociarDeduccionEmpleadoSim @Doc,@TipoDeduccion,@FechaOperacion,@tmp OUTPUT;
                    IF @tmp <> 0 THROW 51003, 'Error procesando DesasociaEmpleadoConDeduccion.', 1;
                    FETCH NEXT FROM curDes INTO @Doc,@TipoDeduccion;
                END;
                CLOSE curDes; DEALLOCATE curDes;

                DECLARE @HoraEntrada DATETIME2(0), @HoraSalida DATETIME2(0);
                DECLARE curMarca CURSOR LOCAL FAST_FORWARD FOR SELECT N.value('@ValorDocumentoIdentidad','VARCHAR(32)'), N.value('@HoraEntrada','DATETIME2(0)'), N.value('@HoraSalida','DATETIME2(0)') FROM @FechaNode.nodes('/FechaOperacion/MarcaAsistencia') X(N);
                OPEN curMarca; FETCH NEXT FROM curMarca INTO @Doc,@HoraEntrada,@HoraSalida;
                WHILE @@FETCH_STATUS = 0
                BEGIN
                    EXEC dbo.sp_ProcesarMarcaAsistencia @Doc,@FechaOperacion,@HoraEntrada,@HoraSalida,@tmp OUTPUT;
                    IF @tmp <> 0 THROW 51004, 'Error procesando MarcaAsistencia.', 1;
                    FETCH NEXT FROM curMarca INTO @Doc,@HoraEntrada,@HoraSalida;
                END;
                CLOSE curMarca; DEALLOCATE curMarca;

                IF dbo.fn_EsJueves(@FechaOperacion) = 1 AND @FechaNode.exist('/FechaOperacion/MarcaAsistencia') = 1
                BEGIN
                    EXEC dbo.sp_CerrarSemana @FechaOperacion, @tmp OUTPUT;
                    IF @tmp <> 0 THROW 51005, 'Error procesando cierre semanal/mensual.', 1;
                END;




                DECLARE curDel CURSOR LOCAL FAST_FORWARD FOR SELECT N.value('@ValorDocumentoIdentidad','VARCHAR(32)') FROM @FechaNode.nodes('/FechaOperacion/EliminarEmpleado') X(N);
                OPEN curDel; FETCH NEXT FROM curDel INTO @Doc;
                WHILE @@FETCH_STATUS = 0
                BEGIN
                    EXEC dbo.sp_EliminarEmpleado @Doc, NULL, @FechaOperacion, NULL, 'SIMULACION', @tmp OUTPUT;
                    IF @tmp <> 0 THROW 51001, 'Error procesando EliminarEmpleado.', 1;
                    FETCH NEXT FROM curDel INTO @Doc;
                END;
                CLOSE curDel; DEALLOCATE curDel;

                DECLARE @Jornada VARCHAR(40), @InicioSemana DATE;
                DECLARE curJor CURSOR LOCAL FAST_FORWARD FOR SELECT N.value('@ValorDocumentoIdentidad','VARCHAR(32)'), N.value('@Jornada','VARCHAR(40)'), N.value('@InicioSemana','DATE') FROM @FechaNode.nodes('/FechaOperacion/AsignarJornada') X(N);
                OPEN curJor; FETCH NEXT FROM curJor INTO @Doc,@Jornada,@InicioSemana;
                WHILE @@FETCH_STATUS = 0
                BEGIN
                    EXEC dbo.sp_AsignarJornadaEmpleado @Doc,@Jornada,@InicioSemana,@tmp OUTPUT;
                    IF @tmp <> 0 THROW 51006, 'Error procesando AsignarJornada.', 1;
                    FETCH NEXT FROM curJor INTO @Doc,@Jornada,@InicioSemana;
                END;
                CLOSE curJor; DEALLOCATE curJor;

                COMMIT TRANSACTION;
            END TRY
            BEGIN CATCH
                IF CURSOR_STATUS('local','curIns') >= 0 CLOSE curIns;
                IF CURSOR_STATUS('local','curIns') > -3 DEALLOCATE curIns;
                IF CURSOR_STATUS('local','curDel') >= 0 CLOSE curDel;
                IF CURSOR_STATUS('local','curDel') > -3 DEALLOCATE curDel;
                IF CURSOR_STATUS('local','curAsoc') >= 0 CLOSE curAsoc;
                IF CURSOR_STATUS('local','curAsoc') > -3 DEALLOCATE curAsoc;
                IF CURSOR_STATUS('local','curDes') >= 0 CLOSE curDes;
                IF CURSOR_STATUS('local','curDes') > -3 DEALLOCATE curDes;
                IF CURSOR_STATUS('local','curMarca') >= 0 CLOSE curMarca;
                IF CURSOR_STATUS('local','curMarca') > -3 DEALLOCATE curMarca;
                IF CURSOR_STATUS('local','curJor') >= 0 CLOSE curJor;
                IF CURSOR_STATUS('local','curJor') > -3 DEALLOCATE curJor;
                IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
                SET @outResultCode = ISNULL(NULLIF(@tmp, 0), 50008);
                THROW;
            END CATCH;

            FETCH NEXT FROM curFecha INTO @FechaOperacion, @FechaNode;
        END;
        CLOSE curFecha; DEALLOCATE curFecha;
        SET @outResultCode = 0;
    END TRY
    BEGIN CATCH
        IF CURSOR_STATUS('local','curFecha') >= 0 CLOSE curFecha;
        IF CURSOR_STATUS('local','curFecha') > -3 DEALLOCATE curFecha;
        IF @outResultCode IS NULL OR @outResultCode = 0 SET @outResultCode = 50008;
        THROW;
    END CATCH
END;
GO
