-- Migración para insertar usuarios mock (Estudiantes)
-- Esto es útil para poblar la base de datos con información para el desarrollo y pruebas de la aplicación.

DO $$
DECLARE
    v_carlos_id uuid := gen_random_uuid();
    v_ana_id uuid := gen_random_uuid();
    v_miguel_id uuid := gen_random_uuid();
    v_laura_id uuid := gen_random_uuid();
    v_diego_id uuid := gen_random_uuid();
BEGIN

    -- 1. Carlos Mendoza
    IF NOT EXISTS (SELECT 1 FROM auth.users WHERE email = 'carlos.estudiante@synaptixfit.com') THEN
        INSERT INTO auth.users (
            instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, 
            raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
            confirmation_token, email_change, email_change_token_new, recovery_token
        ) VALUES (
            '00000000-0000-0000-0000-000000000000', v_carlos_id, 'authenticated', 'authenticated', 'carlos.estudiante@synaptixfit.com', crypt('Password123!', gen_salt('bf')), now(),
            '{"provider": "email", "providers": ["email"]}', 
            '{"full_name": "Carlos Mendoza", "avatar_url": "https://api.dicebear.com/7.x/avataaars/svg?seed=Carlos", "role": "Estudiante"}', 
            now(), now(), '', '', '', ''
        );
    END IF;

    -- 2. Ana Sofia Ramirez
    IF NOT EXISTS (SELECT 1 FROM auth.users WHERE email = 'ana.estudiante@synaptixfit.com') THEN
        INSERT INTO auth.users (
            instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, 
            raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
            confirmation_token, email_change, email_change_token_new, recovery_token
        ) VALUES (
            '00000000-0000-0000-0000-000000000000', v_ana_id, 'authenticated', 'authenticated', 'ana.estudiante@synaptixfit.com', crypt('Password123!', gen_salt('bf')), now(),
            '{"provider": "email", "providers": ["email"]}', 
            '{"full_name": "Ana Sofia Ramirez", "avatar_url": "https://api.dicebear.com/7.x/avataaars/svg?seed=Ana", "role": "Estudiante"}', 
            now(), now(), '', '', '', ''
        );
    END IF;

    -- 3. Miguel Angel Torres
    IF NOT EXISTS (SELECT 1 FROM auth.users WHERE email = 'miguel.estudiante@synaptixfit.com') THEN
        INSERT INTO auth.users (
            instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, 
            raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
            confirmation_token, email_change, email_change_token_new, recovery_token
        ) VALUES (
            '00000000-0000-0000-0000-000000000000', v_miguel_id, 'authenticated', 'authenticated', 'miguel.estudiante@synaptixfit.com', crypt('Password123!', gen_salt('bf')), now(),
            '{"provider": "email", "providers": ["email"]}', 
            '{"full_name": "Miguel Angel Torres", "avatar_url": "https://api.dicebear.com/7.x/avataaars/svg?seed=Miguel", "role": "Estudiante"}', 
            now(), now(), '', '', '', ''
        );
    END IF;

    -- 4. Laura Gomez
    IF NOT EXISTS (SELECT 1 FROM auth.users WHERE email = 'laura.estudiante@synaptixfit.com') THEN
        INSERT INTO auth.users (
            instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, 
            raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
            confirmation_token, email_change, email_change_token_new, recovery_token
        ) VALUES (
            '00000000-0000-0000-0000-000000000000', v_laura_id, 'authenticated', 'authenticated', 'laura.estudiante@synaptixfit.com', crypt('Password123!', gen_salt('bf')), now(),
            '{"provider": "email", "providers": ["email"]}', 
            '{"full_name": "Laura Gomez", "avatar_url": "https://api.dicebear.com/7.x/avataaars/svg?seed=Laura", "role": "Estudiante"}', 
            now(), now(), '', '', '', ''
        );
    END IF;

    -- 5. Diego Fernandez
    IF NOT EXISTS (SELECT 1 FROM auth.users WHERE email = 'diego.estudiante@synaptixfit.com') THEN
        INSERT INTO auth.users (
            instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, 
            raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
            confirmation_token, email_change, email_change_token_new, recovery_token
        ) VALUES (
            '00000000-0000-0000-0000-000000000000', v_diego_id, 'authenticated', 'authenticated', 'diego.estudiante@synaptixfit.com', crypt('Password123!', gen_salt('bf')), now(),
            '{"provider": "email", "providers": ["email"]}', 
            '{"full_name": "Diego Fernandez", "avatar_url": "https://api.dicebear.com/7.x/avataaars/svg?seed=Diego", "role": "Estudiante"}', 
            now(), now(), '', '', '', ''
        );
    END IF;

END $$;
