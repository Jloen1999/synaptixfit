package com.synaptixfit.infrastructure.adapter.output.external.mail;

import java.util.Map;
import org.springframework.web.util.HtmlUtils;

/**
 * Texto del correo para restablecer la contraseña en los cuatro idiomas de la app (es, en, fr, pt; ADR 0017).
 * HTML sencillo con estilos en línea (los clientes de correo ignoran las hojas de estilo), fondo blanco fijado
 * (algunos clientes oscurecen solo parte del correo) y el botón como tabla, que Outlook respeta. Sin el nombre
 * del usuario (ver {@code PasswordResetMailerPort}). Incluye la misma versión en texto plano.
 */
final class PasswordResetEmail {

    private record Texts(String subject, String greeting, String intro, String button, String expiry,
                         String fallback, String ignore, String signature) {
    }

    private static final Map<String, Texts> TEXTS = Map.of(
            "es", new Texts("Restablece tu contraseña de SynaptixFit", "Hola:",
                    "Hemos recibido una petición para cambiar la contraseña de tu cuenta de SynaptixFit.",
                    "Elegir una contraseña nueva", "El enlace caduca en %d minutos y solo sirve una vez.",
                    "Si el botón no funciona, copia esta dirección en el navegador:",
                    "Si no lo has pedido tú, ignora este correo: tu contraseña no cambia.", "El equipo de SynaptixFit"),
            "en", new Texts("Reset your SynaptixFit password", "Hi,",
                    "We received a request to change the password of your SynaptixFit account.",
                    "Choose a new password", "The link expires in %d minutes and works only once.",
                    "If the button doesn’t work, copy this address into your browser:",
                    "If you didn’t ask for this, ignore this email: your password stays the same.",
                    "The SynaptixFit team"),
            "fr", new Texts("Réinitialise ton mot de passe SynaptixFit", "Bonjour,",
                    "Nous avons reçu une demande pour changer le mot de passe de ton compte SynaptixFit.",
                    "Choisir un nouveau mot de passe", "Le lien expire dans %d minutes et ne sert qu’une fois.",
                    "Si le bouton ne fonctionne pas, copie cette adresse dans ton navigateur :",
                    "Si tu n’as rien demandé, ignore cet e-mail : ton mot de passe ne change pas.",
                    "L’équipe SynaptixFit"),
            "pt", new Texts("Repõe a tua palavra-passe do SynaptixFit", "Olá,",
                    "Recebemos um pedido para alterar a palavra-passe da tua conta SynaptixFit.",
                    "Escolher uma nova palavra-passe", "A ligação expira em %d minutos e só funciona uma vez.",
                    "Se o botão não funcionar, copia este endereço para o navegador:",
                    "Se não foste tu a pedir, ignora este email: a tua palavra-passe não muda.",
                    "A equipa SynaptixFit"));

    private PasswordResetEmail() {
    }

    static ResendEmailClient.Message compose(String to, String link, long minutes, String language) {
        String lang = TEXTS.containsKey(language) ? language : "es";
        Texts t = TEXTS.get(lang);
        String expiry = t.expiry().formatted(minutes);
        String safeLink = HtmlUtils.htmlEscape(link);
        String html = """
                <div lang="%s" dir="ltr" style="background:#ffffff;padding:24px;font-family:Arial,Helvetica,\
                sans-serif;max-width:520px;margin:0 auto;color:#1b1d22;line-height:1.5">
                  <p style="font-size:16px;margin:0 0 12px">%s</p>
                  <p style="font-size:16px;margin:0 0 24px">%s</p>
                  <table role="presentation" cellspacing="0" cellpadding="0" border="0" style="margin:0 0 24px">
                    <tr><td style="background:#c6f432;border-radius:12px">
                      <a href="%s" style="display:inline-block;padding:14px 22px;font-size:16px;font-weight:bold;\
                color:#0c0d10;text-decoration:none">%s</a>
                    </td></tr>
                  </table>
                  <p style="font-size:14px;color:#4a4f5a;margin:0 0 12px">%s</p>
                  <p style="font-size:14px;color:#4a4f5a;margin:0 0 4px">%s</p>
                  <p style="font-size:14px;color:#4a4f5a;word-break:break-all;margin:0 0 24px">%s</p>
                  <p style="font-size:14px;color:#4a4f5a;margin:0 0 24px">%s</p>
                  <p style="font-size:14px;margin:0">%s</p>
                </div>
                """.formatted(lang, t.greeting(), t.intro(), safeLink, t.button(), expiry, t.fallback(), safeLink,
                t.ignore(), t.signature());
        String text = String.join("\n\n", t.greeting(), t.intro(), t.button() + ": " + link, expiry, t.ignore(),
                t.signature());
        return new ResendEmailClient.Message(to, t.subject(), html, text);
    }
}
