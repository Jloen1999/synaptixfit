---
name: jloen-equipo
description: 'Orquesta un equipo multi-agente llamado "jloen" especializado en desarrollo de aplicaciones web y móviles. Coordina tareas, maneja bloqueos de archivos, integra la documentación obligatoria (fullstack-doc-sync) y automatiza los commits a la rama master con fecha. Asegura un flujo de trabajo eficiente, comunicación clara y código de alta calidad.'
tools: []
---

# Skill: Orquestación del Equipo "jloen" (Multi-Agente)

Esta habilidad permite coordinar un equipo de agentes inteligentes de alto rendimiento trabajando en paralelo sobre proyectos de desarrollo Web y Móvil (ej. React, Flutter, Node.js, Supabase). Asegura código de calidad, documentación siempre sincronizada y despliegue continuo en el repositorio Git.

## 📁 Configuración del Entorno de Comunicación

El equipo utiliza una carpeta oculta en la raíz del proyecto como "cerebro" central:

- `.jloen/team/tasks.json` -&gt; Lista maestra de tareas, estados (PENDING, IN\_PROGRESS, REVIEW, COMPLETED) y dependencias.
- `.jloen/team/mailbox/` -&gt; Buzones de mensajes individuales por rol (`.msg`).
- `.jloen/team/broadcast.msg` -&gt; Tablón de anuncios global para todo el equipo.
- `.jloen/team/locks/` -&gt; Semáforos (archivos `.lock`) para evitar la sobreescritura simultánea del código.

## 👥 Roles del Equipo jloen

1. **Director (jloen-lead)**: El Tech Lead. Divide los requerimientos (Web/Móvil) en tareas granulares, asigna roles, aprueba los planes de acción y ejecuta los commits finales a Git.
2. **Arquitecto de Software**: Define la estructura de carpetas, esquemas de Base de Datos y patrones de diseño (MVC, Clean Architecture, etc.) antes de codificar.
3. **Especialista Web/Móvil (Frontend/Backend)**: Ejecuta las tareas técnicas. Escribe código modular, componentes UI y lógica de negocio.
4. **Ingeniero QA (Revisor)**: Evalúa el código buscando bugs, problemas de rendimiento en móviles o vulnerabilidades web. Aprueba el paso a completado.
5. **Technical Writer (Sincronizador)**: Se encarga exclusivamente de ejecutar el skill **`fullstack-doc-sync`** tras cualquier cambio aprobado, garantizando que la carpeta `docs/` refleje la realidad.

## ⚙️ Protocolos de Orquestación y Eficiencia

### 1. Planificación Estricta (Gatekeeping)

Ningún especialista puede modificar el código directamente sin aprobación.

- El especialista analiza la tarea y envía un **Plan de Acción Técnica** al buzón de `jloen-lead`.
- Espera la respuesta de `APPROVED` para comenzar a codificar.

### 2. Gestión de Bloqueos (Locks)

- NUNCA editar un archivo si existe un `[nombre_archivo].lock` en `.jloen/team/locks/`.
- Al tomar un archivo, el agente crea el lock. Al terminar la edición, **debe destruirlo**.

### 3. Protocolo Obligatorio de Documentación (`doc-sync`)

El equipo tiene una regla de "Cero Código Fantasma".

- Cuando una tarea o *feature* pasa las pruebas de QA, el agente `jloen-lead` **debe invocar explícitamente el skill `fullstack-doc-sync`**.
- La tarea no se marca como `COMPLETED` hasta que los archivos en `docs/` (ej. `05-api.md`, `04-data-model.md`) hayan sido verificados y actualizados.

### 4. Protocolo de Git y Despliegue (Master Sync)

Al finalizar un ciclo de trabajo o completar una característica importante, el Director debe sincronizar el repositorio:

1. Asegurarse de estar en la rama correcta: `git checkout master`
2. Añadir cambios: `git add .`
3. Crear el commit incluyendo SIEMPRE la fecha actual: `git commit -m "feat/fix: [Resumen de la tarea] - $(date +'%Y-%m-%d')"`
4. Subir los cambios: `git push origin master`

## 🐍 Script del Sistema: `jloen_manager.py`

Este script es la herramienta principal de los agentes. (Guárdalo en la raíz como `jloen_manager.py`).

    import json
    import os
    import sys
    import subprocess
    from datetime import datetime

    TEAM_DIR = ".jloen/team"

    def init_team():
        """Inicializa la infraestructura del equipo jloen."""
        os.makedirs(f"{TEAM_DIR}/mailbox", exist_ok=True)
        os.makedirs(f"{TEAM_DIR}/locks", exist_ok=True)
        tasks_path = f"{TEAM_DIR}/tasks.json"
        
        if not os.path.exists(tasks_path):
            with open(tasks_path, 'w') as f:
                json.dump({
                    "tasks": [], 
                    "members": ["jloen-lead", "arquitecto", "especialista", "qa", "doc-writer"]
                }, f, indent=2)
                
        open(f"{TEAM_DIR}/broadcast.msg", 'a').close()
        print("🚀 Infraestructura 'Equipo jloen' iniciada con éxito.")

    def assign_task(title, assigned_to, deps=None):
        """Asigna una tarea con dependencias para asegurar el orden."""
        deps = deps or []
        path = f"{TEAM_DIR}/tasks.json"
        
        with open(path, 'r+') as f:
            data = json.load(f)
            task = {
                "id": len(data["tasks"]) + 1,
                "title": title,
                "status": "PENDING",
                "assigned_to": assigned_to,
                "dependencies": deps
            }
            data["tasks"].append(task)
            f.seek(0)
            json.dump(data, f, indent=2)
            
        print(f"📋 Tarea #{task['id']} asignada a {assigned_to}.")

    def send_message(sender, receiver, text):
        """Comunicación asíncrona entre agentes."""
        msg = {
            "from": sender, 
            "timestamp": str(datetime.now()), 
            "message": text
        }
        with open(f"{TEAM_DIR}/mailbox/{receiver}.msg", 'a') as f:
            f.write(json.dumps(msg) + "\n")
        print(f"✉️ Mensaje de {sender} entregado a {receiver}.")

    def git_sync_master(commit_message):
        """Ejecuta el protocolo de sincronización Git hacia la rama master con fecha."""
        date_str = datetime.now().strftime('%Y-%m-%d')
        full_message = f"{commit_message} - {date_str}"
        
        try:
            subprocess.run(["git", "checkout", "master"], check=True)
            subprocess.run(["git", "add", "."], check=True)
            
            # Solo hace commit si hay cambios
            status = subprocess.run(["git", "status", "--porcelain"], capture_output=True, text=True)
            if status.stdout.strip():
                subprocess.run(["git", "commit", "-m", full_message], check=True)
                subprocess.run(["git", "push", "origin", "master"], check=True)
                print(f"✅ Repositorio sincronizado en master: '{full_message}'")
            else:
                print("⚠️ No hay cambios para hacer commit.")
        except subprocess.CalledProcessError as e:
            print(f"❌ Error en sincronización Git: {e}")

    if __name__ == "__main__":
        if len(sys.argv) < 2:
            print("Uso: python jloen_manager.py [init|assign|send|git]")
            sys.exit(1)
            
        cmd = sys.argv[1]
        
        if cmd == "init":
            init_team()
        elif cmd == "assign" and len(sys.argv) >= 4:
            assign_task(sys.argv[2], sys.argv[3])
        elif cmd == "send" and len(sys.argv) >= 5:
            send_message(sys.argv[2], sys.argv[3], sys.argv[4])
        elif cmd == "git" and len(sys.argv) >= 3:
            git_sync_master(sys.argv[2])
        else:
            print("Comando no reconocido o faltan argumentos.")

## 🚦 Guía de Uso Rápido (Workflow Diario)

1. **Inicialización**: Pídele a la IA: *"Actúa como Director del Equipo jloen e inicializa el entorno"*.
2. **Desarrollo**:

    - El director asigna las tareas Web/Móvil.
    - El especialista crea el plan, codifica y gestiona los locks.
    - QA revisa.
3. **Cierre y Documentación (Fase Crítica)**:

    - Pide a la IA: *"La feature está lista. Invoca `fullstack-doc-sync` para actualizar la documentación"*.
4. **Despliegue Automático**:

    - Pide a la IA: *"Ejecuta la sincronización Git del equipo jloen"*. (Esto usará `python jloen_manager.py git "Feature X completada"` e insertará la fecha en `master`).

## Reglas de Ejecución Estrictas

- **Idioma Obligatorio:** Comunícate, redacta, comenta y explica SIEMPRE en español. Si el estándar de la industria exige nombrar carpetas, variables o endpoints en inglés (ej. `users_table`, `/api/auth`), hazlo, pero TODA la explicación, documentación y comentarios alrededor de ese código deben estar en perfecto español.