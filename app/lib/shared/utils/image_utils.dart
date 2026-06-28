/// Normaliza una URL de avatar para evitar errores de decodificación
/// en Android (SVG de DiceBear, formatos no soportados).
///
/// Si la URL es de DiceBear en formato SVG, la convierte a PNG.
/// Si la URL es de otro origen pero termina en .svg, la retorna tal cual
/// (el `errorBuilder` de `Image.network` se encargará del fallback).
///
/// Retorna la URL normalizada o la original si no requiere cambios.
String normalizarUrlAvatar(String url) {
  // Detectar DiceBear SVG y convertir a PNG
  // Formatos típicos:
  //   https://api.dicebear.com/7.x/thumbs/svg?seed=xxx
  //   https://api.dicebear.com/9.x/.../svg?seed=xxx
  if (url.contains('dicebear.com') && url.contains('/svg')) {
    return url.replaceAll('/svg', '/png');
  }

  return url;
}
