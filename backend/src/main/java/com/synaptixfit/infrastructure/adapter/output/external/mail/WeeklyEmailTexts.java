package com.synaptixfit.infrastructure.adapter.output.external.mail;

import com.synaptixfit.domain.model.notification.WeeklySummary;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.Locale;
import java.util.Map;
import org.springframework.web.util.HtmlUtils;

/**
 * Textos de los correos del resumen semanal (confirmación y resumen) en es, en, fr y pt. Mismo estilo que
 * {@link PasswordResetEmail}: HTML con estilos en línea, fondo blanco fijado, botón en tabla y versión en texto
 * plano. Los títulos de las entregas los escribe la persona: se escapan.
 */
final class WeeklyEmailTexts {

    private record Texts(String confirmSubject, String confirmIntro, String confirmButton, String confirmIgnore,
                         String subject, String intro, String study, String sessions, String sessionsOf,
                         String blocks, String streak, String upcomingTitle, String nothingUpcoming, String exam,
                         String delivery, String openApp, String footer, String unsubscribe, String hello,
                         String signature) {
    }

    private static final Map<String, Texts> TEXTS = Map.of(
            "es", new Texts("Confirma tu resumen semanal de SynaptixFit",
                    "Pulsa el botón para recibir cada domingo un resumen de tu semana de estudio y entrenamiento.",
                    "Confirmar", "Si no lo has pedido tú, ignora este correo: no te enviaremos nada.",
                    "Tu semana en SynaptixFit", "Así ha ido tu semana:", "Estudio: %s",
                    "Entrenamientos: %d", "Entrenamientos: %d de %d", "Bloques del plan hechos: %d de %d",
                    "Racha: %d días", "Lo que viene en los próximos 7 días",
                    "No tienes entregas ni exámenes en los próximos 7 días.", "Examen", "Entrega",
                    "Abrir SynaptixFit",
                    "Recibes este correo porque activaste el resumen semanal en SynaptixFit.", "Darme de baja",
                    "Hola:", "El equipo de SynaptixFit"),
            "en", new Texts("Confirm your SynaptixFit weekly summary",
                    "Press the button to get a summary of your study and training week every Sunday.",
                    "Confirm", "If you didn’t ask for this, ignore this email: we won’t send you anything.",
                    "Your week on SynaptixFit", "Here’s how your week went:", "Study: %s",
                    "Workouts: %d", "Workouts: %d of %d", "Plan blocks done: %d of %d",
                    "Streak: %d days", "Coming up in the next 7 days",
                    "You have no assignments or exams in the next 7 days.", "Exam", "Assignment",
                    "Open SynaptixFit",
                    "You get this email because you turned on the weekly summary in SynaptixFit.", "Unsubscribe",
                    "Hi,", "The SynaptixFit team"),
            "fr", new Texts("Confirme ton résumé hebdomadaire SynaptixFit",
                    "Appuie sur le bouton pour recevoir chaque dimanche un résumé de ta semaine d’étude et "
                            + "d’entraînement.",
                    "Confirmer", "Si tu n’as rien demandé, ignore cet e-mail : nous ne t’enverrons rien.",
                    "Ta semaine sur SynaptixFit", "Voici comment s’est passée ta semaine :", "Étude : %s",
                    "Entraînements : %d", "Entraînements : %d sur %d", "Créneaux du plan faits : %d sur %d",
                    "Série : %d jours", "À venir dans les 7 prochains jours",
                    "Tu n’as ni rendu ni examen dans les 7 prochains jours.", "Examen", "Rendu",
                    "Ouvrir SynaptixFit",
                    "Tu reçois cet e-mail parce que tu as activé le résumé hebdomadaire dans SynaptixFit.",
                    "Me désabonner", "Bonjour,", "L’équipe SynaptixFit"),
            "pt", new Texts("Confirma o teu resumo semanal do SynaptixFit",
                    "Carrega no botão para receberes todos os domingos um resumo da tua semana de estudo e treino.",
                    "Confirmar", "Se não foste tu a pedir, ignora este email: não te enviaremos nada.",
                    "A tua semana no SynaptixFit", "Foi assim a tua semana:", "Estudo: %s",
                    "Treinos: %d", "Treinos: %d de %d", "Blocos do plano feitos: %d de %d",
                    "Sequência: %d dias", "O que vem nos próximos 7 dias",
                    "Não tens entregas nem exames nos próximos 7 dias.", "Exame", "Entrega",
                    "Abrir o SynaptixFit",
                    "Recebes este email porque ativaste o resumo semanal no SynaptixFit.", "Cancelar subscrição",
                    "Olá,", "A equipa SynaptixFit"));

    private WeeklyEmailTexts() {
    }

    private static String lang(String language) {
        return TEXTS.containsKey(language) ? language : "es";
    }

    static ResendEmailClient.Message confirmation(String to, String language, String confirmUrl) {
        String lang = lang(language);
        Texts t = TEXTS.get(lang);
        String html = layout(lang, t.hello(), "<p style=\"font-size:16px;margin:0 0 24px\">" + t.confirmIntro()
                + "</p>" + button(confirmUrl, t.confirmButton())
                + "<p style=\"font-size:14px;color:#4a4f5a;margin:0 0 24px\">" + t.confirmIgnore() + "</p>",
                t.signature(), "");
        String text = String.join("\n\n", t.hello(), t.confirmIntro(), t.confirmButton() + ": " + confirmUrl,
                t.confirmIgnore(), t.signature());
        return new ResendEmailClient.Message(to, t.confirmSubject(), html, text);
    }

    static ResendEmailClient.Message summary(String to, String language, WeeklySummary s, String appUrl,
                                             String unsubscribeUrl, ZoneId zone) {
        String lang = lang(language);
        Texts t = TEXTS.get(lang);
        Locale locale = Locale.forLanguageTag(lang);
        StringBuilder lines = new StringBuilder();
        StringBuilder plain = new StringBuilder();
        // Solo lo que la persona usa (como en Inicio): sin «Entrenamientos: 0» a quien solo estudia.
        if (s.academic()) {
            line(lines, plain, t.study().formatted(duration(s.studyMinutes())));
        }
        if (s.fitness()) {
            line(lines, plain, s.plannedSessions() == null || s.plannedSessions() == 0
                    ? t.sessions().formatted(s.trainingSessions())
                    : t.sessionsOf().formatted(s.trainingSessions(), s.plannedSessions()));
        }
        if (s.blocksPlanned() > 0) {
            line(lines, plain, t.blocks().formatted(s.blocksCompleted(), s.blocksPlanned()));
        }
        if (s.streak() > 1) {
            line(lines, plain, t.streak().formatted(s.streak()));
        }
        DateTimeFormatter day = DateTimeFormatter.ofPattern("EEE d MMM", locale).withZone(zone);
        StringBuilder upcoming = new StringBuilder();
        StringBuilder upcomingPlain = new StringBuilder();
        for (WeeklySummary.Upcoming u : s.upcoming()) {
            String item = day.format(u.dueAt()) + " · " + (u.exam() ? t.exam() : t.delivery()) + " · ";
            upcoming.append("<li style=\"margin:0 0 6px\">").append(HtmlUtils.htmlEscape(item))
                    .append("<strong>").append(HtmlUtils.htmlEscape(u.title())).append("</strong></li>");
            upcomingPlain.append("- ").append(item).append(u.title()).append('\n');
        }
        String upcomingHtml = !s.academic() ? ""
                : "<p style=\"font-size:16px;font-weight:bold;margin:0 0 8px\">" + t.upcomingTitle() + "</p>"
                + (s.upcoming().isEmpty()
                        ? "<p style=\"font-size:14px;color:#4a4f5a;margin:0 0 24px\">" + t.nothingUpcoming() + "</p>"
                        : "<ul style=\"font-size:14px;margin:0 0 24px;padding-left:20px\">" + upcoming + "</ul>");
        String body = "<p style=\"font-size:16px;margin:0 0 12px\">" + t.intro() + "</p>"
                + "<ul style=\"font-size:16px;margin:0 0 24px;padding-left:20px\">" + lines + "</ul>"
                + upcomingHtml + button(appUrl, t.openApp());
        String footer = "<p style=\"font-size:12px;color:#4a4f5a;margin:24px 0 0\">" + t.footer() + " <a href=\""
                + HtmlUtils.htmlEscape(unsubscribeUrl) + "\" style=\"color:#4a4f5a\">" + t.unsubscribe() + "</a></p>";
        String html = layout(lang, t.hello(), body, t.signature(), footer);
        String upcomingText = !s.academic() ? ""
                : t.upcomingTitle() + ":\n" + (s.upcoming().isEmpty() ? t.nothingUpcoming()
                        : upcomingPlain.toString().strip()) + "\n\n";
        String text = String.join("\n\n", t.hello(), t.intro() + "\n" + plain.toString().strip(),
                upcomingText.strip(), t.openApp() + ": " + appUrl, t.signature(),
                t.footer() + " " + t.unsubscribe() + ": " + unsubscribeUrl).replace("\n\n\n\n", "\n\n");
        return new ResendEmailClient.Message(to, t.subject(), html, text,
                Map.of("List-Unsubscribe", "<" + unsubscribeUrl + ">",
                        "List-Unsubscribe-Post", "List-Unsubscribe=One-Click"));
    }

    private static void line(StringBuilder html, StringBuilder plain, String text) {
        html.append("<li style=\"margin:0 0 6px\">").append(HtmlUtils.htmlEscape(text)).append("</li>");
        plain.append("- ").append(text).append('\n');
    }

    private static String duration(int minutes) {
        int h = minutes / 60;
        int m = minutes % 60;
        return h == 0 ? m + " min" : m == 0 ? h + " h" : h + " h " + m + " min";
    }

    private static String button(String url, String label) {
        return """
                <table role="presentation" cellspacing="0" cellpadding="0" border="0" style="margin:0 0 24px">
                  <tr><td style="background:#c6f432;border-radius:12px">
                    <a href="%s" style="display:inline-block;padding:14px 22px;font-size:16px;font-weight:bold;\
                color:#0c0d10;text-decoration:none">%s</a>
                  </td></tr>
                </table>
                """.formatted(HtmlUtils.htmlEscape(url), label);
    }

    private static String layout(String lang, String greeting, String body, String signature, String footer) {
        return """
                <div lang="%s" dir="ltr" style="background:#ffffff;padding:24px;font-family:Arial,Helvetica,\
                sans-serif;max-width:520px;margin:0 auto;color:#1b1d22;line-height:1.5">
                  <p style="font-size:16px;margin:0 0 12px">%s</p>
                  %s
                  <p style="font-size:14px;margin:0">%s</p>
                  %s
                </div>
                """.formatted(lang, greeting, body, signature, footer);
    }
}
