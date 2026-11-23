-- =============================================================================
-- REVISIÓN: borrado lógico de documentos de archivo - re-ejecutable
-- El front ya tenía "Eliminar" pero el endpoint no existía. Un documento eliminado se conserva con su estado, quién y
-- cuándo lo eliminó (se puede recuperar cambiando documento_estado a ACTIVO).
-- Voluntarios, actividades y asignaciones usan sus columnas de estado existentes (valor ELIMINADO/ELIMINADA).
-- =============================================================================
ALTER TABLE archivo.documentos ADD COLUMN IF NOT EXISTS documento_estado text DEFAULT 'ACTIVO';
ALTER TABLE archivo.documentos ADD COLUMN IF NOT EXISTS documento_eliminado_por integer;
ALTER TABLE archivo.documentos ADD COLUMN IF NOT EXISTS documento_eliminado_en timestamp without time zone;
