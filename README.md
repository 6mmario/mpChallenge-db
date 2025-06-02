## **1. Entidad**

## **Fiscalía**

- **Técnico:**
    - Se creó porque cada fiscal pertenece a una fiscalía concreta.
    - La clave principal es FiscaliaID, de tipo entero autoincremental.
    - Sus atributos (NombreFiscalia, Ubicacion, Telefono) guardan los datos de esa oficina.
    - Relación 1:N con Fiscal (una fiscalía contiene varios fiscales).

---

## **2. Entidad**

## **Fiscal**

## **(usuario)**

- **Técnico:**
    - Representa al “usuario” (fiscal) que se autentica y atiende casos.
    - FiscalID es la PK (autoincremental).
    - Atributos de usuario:
        - Nombre, CorreoElectronico, Usuario, Contrasena (almacena hash), Rol.
        - Rol permite distinguir, por ejemplo, “FISCAL” vs. “SUPERVISOR” (si necesitamos control de acceso por nivel).
    - Tiene una clave foránea FiscaliaID que lo enlaza a la tabla Fiscalía.
    - Relación 1:N con Caso (un fiscal puede tener varios casos asignados).

---

## **3. Entidad**

## **Caso**

- **Técnico:**
    - Guarda cada caso judicial o administrativo que se está gestionando.
    - CasoID es la PK (autoincremental).
    - Atributos:
        - FechaRegistro (fecha en que se creó, con DEFAULT a SYSUTCDATETIME()).
        - Estado (p. ej.: 'PENDIENTE', 'EN_PROGRESO', 'CERRADO').
        - Progreso (texto corto o porcentaje: '0%', '50%', '100%').
        - Descripcion (detalle del caso).
        - FechaUltimaActualizacion (timestamp, para saber cuándo cambió por última vez).
        - FiscalID (FK a Fiscal, el responsable actual del caso).
    - Relación N:1 con Fiscal (cada caso está asignado a un solo fiscal a la vez).

---

## **4. Entidad**

## **Informe**

- **Técnico:**
    - Guarda cada informe que se genera sobre casos.
    - InformeID es la PK (autoincremental).
    - Atributos:
        - FechaGeneracion (timestamp al insertar, con DEFAULT SYSUTCDATETIME()).
        - TipoInforme (texto para clasificar: “Informe mensual”, “Informe semanal”, etc.).
        - DescripcionBreve (texto corto con detalles).
    - No tiene FK directa a Caso, porque la relación con casos se hace a través de la tabla intermedia Informe_Caso.

---

## **5. Entidad**

## **Informe_Caso**

## **(tablas asociativas)**

- **Técnico:**
    - Tabla con PK compuesta (InformeID, CasoID).
    - FK a Informe(InformeID) y FK a Caso(CasoID).
    - Sirve para relacionar los informes con los casos que cubren.

---

## **6. Entidad**

## **Permiso  y Fiscal_Permiso**

- **Técnico:**
    - **Permiso**:
        - PermisoID (PK).
        - NombrePermiso ('CREAR_CASO', 'ASIGNAR_CASO', 'VER_INFORMES', etc.).
        - Descripcion (texto corto opcional).
    - **Fiscal_Permiso** (asociativa):
        - PK compuesta (FiscalID, PermisoID).
        - FK a Fiscal(FiscalID) y a Permiso(PermisoID).
        - Relación N:M entre fiscales y permisos.

---

## **7. Entidad**

## **LogReasignacionFallida**

- **Técnico:**
    - Guarda cada intento de reasignar un caso que no cumplió las reglas.
    - LogID (PK, autoincremental).
    - Atributos:
        - FechaHoraIntento (timestamp, con DEFAULT SYSUTCDATETIME()).
        - Motivo (texto que explica por qué falló: “Estado distinto de PENDIENTE” o “Fiscalía diferente”).
        - CasoID (FK a Caso).
        - FiscalAnteriorID (FK a Fiscal, el que originalmente tenía el caso).
        - FiscalNuevoID (FK a Fiscal, a quien intentaron reasignar).

---

## **Resumen de las Reglas de Negocio y cómo el ER las refleja**

1. **Cada fiscal pertenece a una fiscalía**
    - Reflejado conectando Fiscal.FiscaliaID → Fiscalía.FiscaliaID.
    - Permite validar que, al reasignar, el nuevo fiscal esté en la misma oficina.
2. **Un caso sólo puede reasignarse si está ‘PENDIENTE’**
    - El atributo Estado en Caso controla esto.
    - El procedimiento de reasignación (almacenado) lee Estado; si no es 'PENDIENTE', inserta un registro en LogReasignacionFallida y no cambia nada.
3. **Un caso sólo puede reasignarse a un fiscal de la misma fiscalía**
    - El paso de reasignación compara FiscaliaID del fiscal actual (tomado de Caso.FiscalID) con FiscaliaID del NuevoFiscalID (tomado de Fiscal).
    - Si no coinciden, se inserta en LogReasignacionFallida.
4. **Control de permisos**
    - Mediante Permiso y Fiscal_Permiso definimos quién puede “crear casos”, “asignar casos” o “ver informes”.
    - De esta manera, la lógica de la aplicación puede verificar en qué tabla está el permiso de cada usuario sin duplicar datos.
5. **Generación de informes sobre casos**
    - Los informes se almacenan en Informe, con su fecha de creación y descripción.
    - La relación N:M con Caso se modela con Informe_Caso, lo que permite agrupar varios casos en un informe y usar un caso en múltiples informes.
6. **Auditoría de intentos fallidos**
    - Si alguien intenta reasignar sin cumplir reglas, LogReasignacionFallida almacena:
        - Fecha/hora del intento,
        - Motivo de falla,
        - CasoID,
        - FiscalAnteriorID y FiscalNuevoID.
    - Esa tabla no conecta directamente a informes ni permisos, porque su único propósito es guardar el historial de errores en las reasignaciones.

---