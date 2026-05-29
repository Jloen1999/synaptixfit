-- Migration: 0033_actualizar_urls_gif_a_mp4
-- Objetivo: Actualizar url_gif de .gif a .mp4 en ejercicios existentes
--           tras la estandarizacion de todos los videos a formato MP4.
update public.ejercicios set url_gif = replace(url_gif, '.gif', '.mp4') where url_gif like '%.gif';
