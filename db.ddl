--------------------------------------------------------------------------------
-- 1. CREAR LA TABLA FISCALÍA
--------------------------------------------------------------------------------
CREATE TABLE dbo.Fiscalia (
    FiscaliaID            INT              IDENTITY(1,1) PRIMARY KEY,
    NombreFiscalia        NVARCHAR(100)    NOT NULL,
    Ubicacion             NVARCHAR(200)    NULL,
    Telefono              NVARCHAR(50)     NULL
);
GO

--------------------------------------------------------------------------------
-- 2. CREAR LA TABLA FISCAL (USUARIO)
--------------------------------------------------------------------------------
CREATE TABLE dbo.Fiscal (
    FiscalID              INT              IDENTITY(1,1) PRIMARY KEY,
    Nombre                NVARCHAR(100)    NOT NULL,
    CorreoElectronico     NVARCHAR(100)    NOT NULL,
    Usuario               NVARCHAR(50)     NOT NULL,
    Contrasena            NVARCHAR(255)    NOT NULL,    -- guardar hash de contraseña
    Rol                   NVARCHAR(50)     NOT NULL,    -- p.ej.: 'FISCAL', 'ADMIN', etc.
    FiscaliaID            INT              NOT NULL
        CONSTRAINT FK_Fiscal_Fiscalia REFERENCES dbo.Fiscalia(FiscaliaID)
);
GO

--------------------------------------------------------------------------------
-- 3. CREAR LA TABLA CASO
--------------------------------------------------------------------------------
CREATE TABLE dbo.Caso (
    CasoID                    INT              IDENTITY(1,1) PRIMARY KEY,
    FechaRegistro             DATETIME2        NOT NULL CONSTRAINT DF_Caso_FechaRegistro DEFAULT SYSUTCDATETIME(),
    Estado                    NVARCHAR(50)     NOT NULL,      -- p.ej.: 'PENDIENTE', 'EN_PROGRESO', 'CERRADO'
    Progreso                  NVARCHAR(50)     NULL,          -- porcentaje o texto corto
    Descripcion               NVARCHAR(MAX)    NULL,
    FechaUltimaActualizacion  DATETIME2        NULL,
    FiscalID                  INT              NOT NULL
        CONSTRAINT FK_Caso_Fiscal REFERENCES dbo.Fiscal(FiscalID)
);
GO

--------------------------------------------------------------------------------
-- 4. CREAR LA TABLA INFORME
--------------------------------------------------------------------------------
CREATE TABLE dbo.Informe (
    InformeID           INT              IDENTITY(1,1) PRIMARY KEY,
    FechaGeneracion     DATETIME2        NOT NULL CONSTRAINT DF_Informe_FechaGeneracion DEFAULT SYSUTCDATETIME(),
    TipoInforme         NVARCHAR(100)    NOT NULL,    -- p.ej.: 'Estado de casos', 'Estadísticas mensuales'
    DescripcionBreve    NVARCHAR(255)    NULL
);
GO

--------------------------------------------------------------------------------
-- 5. CREAR LA TABLA PERMISO
--------------------------------------------------------------------------------
CREATE TABLE dbo.Permiso (
    PermisoID           INT              IDENTITY(1,1) PRIMARY KEY,
    NombrePermiso       NVARCHAR(100)    NOT NULL,    -- p.ej.: 'CREAR_CASO', 'ASIGNAR_CASO', 'VER_INFORMES'
    Descripcion         NVARCHAR(255)    NULL
);
GO

--------------------------------------------------------------------------------
-- 6. CREAR LA ENTIDAD ASOCIATIVA INFORME_CASO (RELACIÓN N:M)
--------------------------------------------------------------------------------
CREATE TABLE dbo.Informe_Caso (
    InformeID           INT              NOT NULL,
    CasoID              INT              NOT NULL,
    CONSTRAINT PK_Informe_Caso PRIMARY KEY (InformeID, CasoID),
    CONSTRAINT FK_InformeCaso_Informe FOREIGN KEY (InformeID) REFERENCES dbo.Informe(InformeID),
    CONSTRAINT FK_InformeCaso_Caso    FOREIGN KEY (CasoID)    REFERENCES dbo.Caso(CasoID)
);
GO

--------------------------------------------------------------------------------
-- 7. CREAR LA ENTIDAD ASOCIATIVA FISCAL_PERMISO (RELACIÓN N:M)
--------------------------------------------------------------------------------
CREATE TABLE dbo.Fiscal_Permiso (
    FiscalID            INT              NOT NULL,
    PermisoID           INT              NOT NULL,
    CONSTRAINT PK_Fiscal_Permiso PRIMARY KEY (FiscalID, PermisoID),
    CONSTRAINT FK_FiscalPermiso_Fiscal  FOREIGN KEY (FiscalID)  REFERENCES dbo.Fiscal(FiscalID),
    CONSTRAINT FK_FiscalPermiso_Permiso FOREIGN KEY (PermisoID) REFERENCES dbo.Permiso(PermisoID)
);
GO

--------------------------------------------------------------------------------
-- 8. CREAR LA TABLA LOGREASIGNACIONFALLIDA
--------------------------------------------------------------------------------
CREATE TABLE dbo.LogReasignacionFallida (
    LogID                  INT              IDENTITY(1,1) PRIMARY KEY,
    FechaHoraIntento       DATETIME2        NOT NULL CONSTRAINT DF_LogReasignacionFallida_FechaHoraIntento DEFAULT SYSUTCDATETIME(),
    Motivo                 NVARCHAR(255)    NOT NULL,
    CasoID                 INT              NOT NULL
        CONSTRAINT FK_LogReasignacion_Caso         REFERENCES dbo.Caso(CasoID),
    FiscalAnteriorID       INT              NOT NULL
        CONSTRAINT FK_LogReasignacion_FiscalAnt    REFERENCES dbo.Fiscal(FiscalID),
    FiscalNuevoID          INT              NOT NULL
        CONSTRAINT FK_LogReasignacion_FiscalNuevo  REFERENCES dbo.Fiscal(FiscalID)
);
GO

--------------------------------------------------------------------------------
-- ÍNDICES ADICIONALES (UNO POR CADA FK PARA MEJORAR PERFORMANCE, OPCIONAL)
--------------------------------------------------------------------------------
-- Índices en fiscalía, caso, informe, permiso y tablas asociativas
CREATE INDEX IX_Fiscal_FiscaliaID ON dbo.Fiscal(FiscaliaID);
CREATE INDEX IX_Caso_FiscalID ON dbo.Caso(FiscalID);
CREATE INDEX IX_LogReasignacion_CasoID ON dbo.LogReasignacionFallida(CasoID);
CREATE INDEX IX_LogReasignacion_FiscalAntID ON dbo.LogReasignacionFallida(FiscalAnteriorID);
CREATE INDEX IX_LogReasignacion_FiscalNuevoID ON dbo.LogReasignacionFallida(FiscalNuevoID);
CREATE INDEX IX_Informe_Caso_InformeID ON dbo.Informe_Caso(InformeID);
CREATE INDEX IX_Informe_Caso_CasoID ON dbo.Informe_Caso(CasoID);
CREATE INDEX IX_Fiscal_Permiso_FiscalID ON dbo.Fiscal_Permiso(FiscalID);
CREATE INDEX IX_Fiscal_Permiso_PermisoID ON dbo.Fiscal_Permiso(PermisoID);
GO