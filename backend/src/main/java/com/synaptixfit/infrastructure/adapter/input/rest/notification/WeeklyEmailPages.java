package com.synaptixfit.infrastructure.adapter.input.rest.notification;

import java.util.Map;
import org.springframework.web.util.HtmlUtils;

/**
 * Páginas sencillas que abren los enlaces del correo del resumen semanal, en es, en, fr y pt. HTML estático con
 * los colores de la app; no muestra datos de la persona. Abrir el enlace (GET) solo enseña un botón: la acción se
 * hace con POST, para que los analizadores de enlaces de los correos (que abren las URL solos) no confirmen ni den
 * de baja a nadie.
 */
final class WeeklyEmailPages {

    enum Kind { CONFIRM_PROMPT, UNSUBSCRIBE_PROMPT, CONFIRMED, UNSUBSCRIBED, INVALID }

    private record Texts(String confirmPromptTitle, String confirmPromptBody, String confirmButton,
                         String unsubscribePromptTitle, String unsubscribePromptBody, String unsubscribeButton,
                         String confirmedTitle, String confirmedBody, String unsubscribedTitle,
                         String unsubscribedBody, String invalidTitle, String invalidBody) {
    }

    private static final Map<String, Texts> TEXTS = Map.of(
            "es", new Texts("Confirma tu resumen semanal",
                    "Pulsa el botón para empezar a recibir cada domingo un resumen de tu semana.", "Confirmar",
                    "¿Darte de baja del resumen semanal?",
                    "Dejarás de recibirlo. Puedes volver a activarlo en la app, en Ajustes › Notificaciones.",
                    "Darme de baja",
                    "Resumen semanal activado",
                    "Cada domingo recibirás un resumen de tu semana. Puedes desactivarlo cuando quieras desde la app "
                            + "o con el enlace de cada correo.",
                    "Te has dado de baja", "No volverás a recibir el resumen semanal. Puedes activarlo de nuevo "
                            + "en la app, en Ajustes › Notificaciones.",
                    "Enlace no válido", "Este enlace ya no sirve. Gestiona el resumen semanal desde la app, en "
                            + "Ajustes › Notificaciones."),
            "en", new Texts("Confirm your weekly summary",
                    "Press the button to start getting a summary of your week every Sunday.", "Confirm",
                    "Unsubscribe from the weekly summary?",
                    "You’ll stop getting it. You can turn it back on in the app, in Settings › Notifications.",
                    "Unsubscribe",
                    "Weekly summary turned on",
                    "Every Sunday you’ll get a summary of your week. You can turn it off any time in the app or "
                            + "with the link in each email.",
                    "You’ve unsubscribed", "You won’t get the weekly summary again. You can turn it back on in "
                            + "the app, in Settings › Notifications.",
                    "Invalid link", "This link no longer works. Manage the weekly summary in the app, in "
                            + "Settings › Notifications."),
            "fr", new Texts("Confirme ton résumé hebdomadaire",
                    "Appuie sur le bouton pour recevoir chaque dimanche un résumé de ta semaine.", "Confirmer",
                    "Te désabonner du résumé hebdomadaire ?",
                    "Tu ne le recevras plus. Tu peux le réactiver dans l’app, dans Réglages › Notifications.",
                    "Me désabonner",
                    "Résumé hebdomadaire activé",
                    "Chaque dimanche, tu recevras un résumé de ta semaine. Tu peux le désactiver quand tu veux dans "
                            + "l’app ou avec le lien de chaque e-mail.",
                    "Tu t’es désabonné", "Tu ne recevras plus le résumé hebdomadaire. Tu peux le réactiver dans "
                            + "l’app, dans Réglages › Notifications.",
                    "Lien non valide", "Ce lien ne fonctionne plus. Gère le résumé hebdomadaire dans l’app, dans "
                            + "Réglages › Notifications."),
            "pt", new Texts("Confirma o teu resumo semanal",
                    "Carrega no botão para começares a receber todos os domingos um resumo da tua semana.",
                    "Confirmar",
                    "Cancelar a subscrição do resumo semanal?",
                    "Deixas de o receber. Podes voltar a ativá-lo na app, em Definições › Notificações.",
                    "Cancelar subscrição",
                    "Resumo semanal ativado",
                    "Todos os domingos vais receber um resumo da tua semana. Podes desativá-lo quando quiseres na "
                            + "app ou com a ligação de cada email.",
                    "Cancelaste a subscrição", "Não voltarás a receber o resumo semanal. Podes ativá-lo de novo "
                            + "na app, em Definições › Notificações.",
                    "Ligação inválida", "Esta ligação já não funciona. Gere o resumo semanal na app, em "
                            + "Definições › Notificações."));

    private WeeklyEmailPages() {
    }

    /** @param token token del enlace, para el formulario de las páginas con botón (nulo en las demás) */
    static String render(Kind kind, String language, String token) {
        String lang = TEXTS.containsKey(language) ? language : "es";
        Texts t = TEXTS.get(lang);
        String[] content = switch (kind) {
            case CONFIRM_PROMPT -> new String[] {t.confirmPromptTitle(), t.confirmPromptBody(), t.confirmButton()};
            case UNSUBSCRIBE_PROMPT ->
                    new String[] {t.unsubscribePromptTitle(), t.unsubscribePromptBody(), t.unsubscribeButton()};
            case CONFIRMED -> new String[] {t.confirmedTitle(), t.confirmedBody(), null};
            case UNSUBSCRIBED -> new String[] {t.unsubscribedTitle(), t.unsubscribedBody(), null};
            case INVALID -> new String[] {t.invalidTitle(), t.invalidBody(), null};
        };
        String form = content[2] == null || token == null ? "" : """
                <form method="post" action="?token=%s" style="margin:24px 0 0">
                <button type="submit" style="background:#c6f432;color:#0c0d10;border:0;border-radius:12px;\
                padding:14px 22px;font-size:16px;font-weight:bold;cursor:pointer">%s</button>
                </form>
                """.formatted(HtmlUtils.htmlEscape(token), content[2]);
        return """
                <!doctype html>
                <html lang="%s"><head><meta charset="utf-8">
                <meta name="viewport" content="width=device-width, initial-scale=1">
                <meta name="robots" content="noindex">
                <title>%s · SynaptixFit</title></head>
                <body style="margin:0;background:#0c0d10;color:#f2f3f5;font-family:Arial,Helvetica,sans-serif">
                <main style="max-width:480px;margin:15vh auto;padding:24px">
                <p style="color:#c6f432;font-weight:bold;margin:0 0 8px">SynaptixFit</p>
                <h1 style="font-size:24px;margin:0 0 12px">%s</h1>
                <p style="font-size:16px;line-height:1.5;margin:0">%s</p>
                %s
                </main></body></html>
                """.formatted(lang, content[0], content[0], content[1], form);
    }
}
