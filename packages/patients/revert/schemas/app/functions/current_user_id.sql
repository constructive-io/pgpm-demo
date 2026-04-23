-- Revert schemas/app/functions/current_user_id from pg

DROP FUNCTION app.current_user_id();
