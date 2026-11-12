"""Verifica los paquetes en destinos temporales; no instala ni publica nada."""
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import unittest
import uuid

import yaml

ROOT = Path(__file__).resolve().parents[1]
PWSH = shutil.which("pwsh")
WINDOWS_POWERSHELL = shutil.which("powershell") or shutil.which("powershell.exe")
INSTALACION = ROOT / "instalacion.json"
VALORES = (json.loads(INSTALACION.read_text(encoding="utf-8")) if INSTALACION.is_file() else
           {"aprobador": "{{" + "APROBADOR" + "}}", "arnes": "{{" + "ARNES" + "}}"})
APROBADOR = VALORES["aprobador"]
ARNES = VALORES["arnes"]
SKILLS = {"codegraph", "context-handoff", "context-resume", "project-init", "thread-rescue",
          "worktree-create", "worktree-pause", "worktree-reactivate", "worktree-transfer",
          "worktree-close"}


def run(*args, input=None, env=None):
    return subprocess.run([str(a) for a in args], input=input, text=True,
                          encoding="utf-8", capture_output=True, env=env)


def frontmatter(path):
    match = re.match(r"^---\n(.*?)\n---\n", path.read_text(encoding="utf-8"), re.S)
    if not match:
        raise AssertionError(f"Falta frontmatter: {path}")
    return yaml.safe_load(match[1])


def contents(root):
    return {str(p.relative_to(root)): p.read_bytes()
            for p in root.rglob("*") if p.is_file()}


def prepare_bare_remote(seed, remote, branch="dev"):
    result = run("git", "init", "-q", "--bare", remote)
    if result.returncode:
        raise AssertionError(result.stderr)
    shutil.copytree(seed / ".git/objects", remote / "objects", dirs_exist_ok=True)
    shutil.copytree(seed / ".git/refs", remote / "refs", dirs_exist_ok=True)
    (remote / "HEAD").write_text(f"ref: refs/heads/{branch}\n", encoding="utf-8")


class Templates(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        if not PWSH:
            raise RuntimeError("Se requiere PowerShell 7 (pwsh) para probar la copia.")
        cls.destination = ROOT.parent / f"plantillas-{uuid.uuid4().hex}"
        cls.destination.mkdir()
        cls.packages = {}
        for kind, source in (("producto", "plantilla-proyecto"),
                             ("coordinacion", "plantilla-coordinacion")):
            dest = cls.destination / kind
            result = run(PWSH, "-NoProfile", "-File", ROOT / "scripts/Preparar-Plantilla.ps1",
                         "-Tipo", kind, "-Destino", dest)
            if result.returncode:
                shutil.rmtree(cls.destination, ignore_errors=True)
                raise RuntimeError(result.stderr)
            cls.packages[source] = dest

    @classmethod
    def tearDownClass(cls):
        shutil.rmtree(cls.destination, ignore_errors=True)

    def test_copy_includes_hidden_files_and_only_selected_package(self):
        for source, dest in self.packages.items():
            self.assertEqual(contents(ROOT / source), contents(dest))
            self.assertTrue((dest / ".gitignore").is_file())
            self.assertTrue((dest / ".github/pull_request_template.md").is_file())
            self.assertFalse((dest / ".git").exists())
            self.assertFalse((dest / "OWNERS.md").exists())

    def test_copy_refuses_nonempty_destination_without_changing_it(self):
        dest = self.packages["plantilla-proyecto"]
        before = contents(dest)
        result = run(PWSH, "-NoProfile", "-File", ROOT / "scripts/Preparar-Plantilla.ps1",
                     "-Tipo", "coordinacion", "-Destino", dest)
        self.assertNotEqual(0, result.returncode)
        self.assertEqual(before, contents(dest))

    def test_copy_refuses_destination_inside_harness(self):
        dest = ROOT / ".verificacion/prohibido"
        result = run(PWSH, "-NoProfile", "-File", ROOT / "scripts/Preparar-Plantilla.ps1",
                     "-Tipo", "producto", "-Destino", dest)
        self.assertNotEqual(0, result.returncode)
        self.assertFalse(dest.exists())

    def test_gitignore_protects_local_files_and_keeps_examples(self):
        blocked = {".env", ".env.local", ".env.production", "nested/.env",
                   "nested/.env.test", "app.log", "scratch.tmp", "tmp/result.json",
                   ".DS_Store", "Thumbs.db"}
        keep = {".env.example", ".env.production.example", "nested/.env.example",
                "nested/.env.test.example", "src/main.ts", "package-lock.json",
                "requirements.lock", "docs/example.json", ".github/workflows/check.yml"}
        # Copias adicionales: no alterar los paquetes usados por otros chequeos.
        for source, dest in self.packages.items():
            fixture = self.destination / ("git-" + source)
            shutil.copytree(dest, fixture)
            initialized = run("git", "init", "-q", fixture)
            self.assertEqual(0, initialized.returncode, initialized.stderr)
            result = run("git", "-C", fixture, "-c", "core.excludesFile=",
                         "check-ignore", "--no-index", "--stdin", "-z",
                         input="\0".join(sorted(blocked | keep)) + "\0")
            self.assertEqual(0, result.returncode, result.stderr)
            self.assertEqual(blocked, set(filter(None, result.stdout.split("\0"))))

        # El ignore del arnés tampoco debe ocultar ejemplos dentro de plantillas.
        paths = ["plantilla-proyecto/.env.example",
                 "plantilla-proyecto/.env.production.example",
                 "plantilla-coordinacion/.env.example"]
        result = run("git", "-C", ROOT, "-c", "core.excludesFile=", "check-ignore",
                     "--no-index", "--stdin", "-z", input="\0".join(paths) + "\0")
        self.assertEqual(1, result.returncode, result.stderr)
        self.assertEqual("", result.stdout)

    def test_product_has_no_internal_process_references(self):
        forbidden = re.compile(
            r"saniti[sz]|arn[eé]s|harness|codex|claude|workers?|worktrees?|"
            r"handoffs?|prompts?|\bchats?\b|\bWT\d*\b|coordinaci[oó]n|"
            r"repositorios? privados?|documentaci[oó]n p[uú]blica|" + re.escape(ARNES), re.I)
        for path in self.packages["plantilla-proyecto"].rglob("*"):
            if path.is_file():
                self.assertIsNone(forbidden.search(path.read_text(encoding="utf-8")), str(path))

    def test_markdown_links_resolve_within_each_package(self):
        groups = list(self.packages.values())
        for base in groups:
            for path in base.rglob("*.md"):
                self.check_links(path, base)
        for folder in ("docs", "personal", ".agents", ".claude"):
            for path in (ROOT / folder).rglob("*.md"):
                self.check_links(path, ROOT)
        self.check_links(ROOT / "README.md", ROOT)

    def check_links(self, path, boundary):
        for target in re.findall(r"\[[^\]]+\]\(([^)]+)\)", path.read_text(encoding="utf-8")):
            if re.match(r"^[a-z]+://", target) or target.startswith("#"):
                continue
            target = target.split("#", 1)[0]
            resolved = (path.parent / target).resolve()
            self.assertTrue(resolved.is_relative_to(boundary.resolve()), f"{path}: {target}")
            self.assertTrue(resolved.exists(), f"{path}: enlace roto {target}")

    def test_issue_templates_and_labels(self):
        base = self.packages["plantilla-coordinacion"]
        labels = json.loads((base / "labels.json").read_text(encoding="utf-8"))
        names = {label["name"] for label in labels}
        self.assertEqual(len(labels), len(names))
        for label in labels:
            self.assertRegex(label["color"], r"^[a-fA-F0-9]{6}$")
            self.assertTrue(label["description"])
        paths = list((base / ".github/ISSUE_TEMPLATE").glob("*.md"))
        self.assertEqual(5, len(paths))
        for path in paths:
            data = frontmatter(path)
            self.assertEqual({"name", "about", "title", "labels", "assignees"}, set(data))
            for field in ("name", "about", "title"):
                self.assertTrue(data[field])
            self.assertIn(data["labels"], names)
            text = path.read_text(encoding="utf-8")
            self.assertIn("Destino verificado", text)
            self.assertIn("Proyecto del que viene", text)
            self.assertIn("WT:", text)
            self.assertIn("Plataforma:", text)
        config = yaml.safe_load((base / ".github/ISSUE_TEMPLATE/config.yml").read_text())
        self.assertIs(config["blank_issues_enabled"], False)

        readme = (base / "README.md").read_text(encoding="utf-8")
        self.assertIn("Incidencias del arnés", readme)
        self.assertIn(ARNES, readme)
        self.assertIn("Si hay duda", readme)

    def test_harness_event_issue_template_is_factual_not_prescriptive(self):
        path = ROOT / ".github/ISSUE_TEMPLATE/evento.md"
        self.assertTrue(path.is_file())
        data = frontmatter(path)
        self.assertEqual("Evento observado", data["name"])
        self.assertEqual("workflow", data["labels"])
        text = path.read_text(encoding="utf-8")
        self.assertIn(f"Destino verificado: {ARNES}", text)
        self.assertIn("No incluir solución propuesta", text)
        self.assertIn("No incluir plan de implementación", text)
        self.assertIn("hipótesis", text)
        self.assertIn("worker que tome la Issue", text)
        # La publicación crea esa etiqueta en el repo del arnés.
        publish = (ROOT / "scripts/Publicar-Arnes.ps1").read_text(encoding="utf-8-sig")
        self.assertIn(f"$etiquetaEventos = '{data['labels']}'", publish)
        self.assertIn("gh label create $etiquetaEventos --repo $repoArnes", publish)

    def test_skill_packages(self):
        for runtime in (".agents", ".claude"):
            paths = list((ROOT / runtime / "skills").glob("*/SKILL.md"))
            self.assertEqual(SKILLS, {p.parent.name for p in paths})
            for path in paths:
                data = frontmatter(path)
                self.assertEqual(path.parent.name, data["name"])
                self.assertTrue(isinstance(data["description"], str) and data["description"])
                allowed = {"name", "description", "metadata", "license", "allowed-tools"}
                if runtime == ".claude":
                    allowed |= {"argument-hint", "disable-model-invocation"}
                    if "disable-model-invocation" in data:
                        self.assertIsInstance(data["disable-model-invocation"], bool)
                self.assertFalse(set(data) - allowed, str(path))
                if runtime == ".agents":
                    ui = yaml.safe_load((path.parent / "agents/openai.yaml").read_text(encoding="utf-8"))
                    self.assertIn("$" + path.parent.name, ui["interface"]["default_prompt"])
                    self.assertTrue(25 <= len(ui["interface"]["short_description"]) <= 64)

    def test_project_init_keeps_first_bootstrap_light_and_named(self):
        for runtime in (".agents", ".claude"):
            text = (ROOT / runtime / "skills/project-init/SKILL.md").read_text(encoding="utf-8")
            self.assertIn("00_[WT]_[NOMBRE]", text)
            self.assertIn("Generar-CodeGraph.ps1", text)
            self.assertRegex(text, r"resumen\.md")
            self.assertRegex(text, r"lectura inicial")
            self.assertRegex(text, r"No le(?:er|as) especificaciones completas")

        guide = (ROOT / "docs/Plantilla_Inicio_Sesion.md").read_text(encoding="utf-8")
        self.assertIn("00_WT01_Revisión inicial", guide)
        self.assertIn("generá CodeGraph inicial", guide)
        self.assertIn("mi-org/mi-producto", guide)

    def test_context_resume_normalizes_successor_chat_name(self):
        for runtime in (".agents", ".claude"):
            text = (ROOT / runtime / "skills/context-resume/SKILL.md").read_text(encoding="utf-8")
            self.assertIn("00_[WT]_[NOMBRE]", text)
            self.assertRegex(text, r"chat actual debe llamarse")
            self.assertRegex(text, r"No de(?:jar|jes) el chat con el texto del prompt")
            self.assertIn("Continuá WTxx", text)

        contract = (ROOT / "docs/CONTRATO_HANDOFF.md").read_text(encoding="utf-8")
        self.assertIn("Normalizar el nombre del chat actual", contract)
        self.assertIn("No dejar el sucesor con el texto del prompt inicial", contract)

    def test_context_handoff_does_not_monitor_successor_by_default(self):
        for runtime in (".agents", ".claude"):
            text = (ROOT / runtime / "skills/context-handoff/SKILL.md").read_text(encoding="utf-8")
            self.assertIn("XX_[WT]_[VERSIÓN]_[NOMBRE]", text)
            self.assertIn("00_[WT]_[NOMBRE]", text)
            self.assertRegex(text, r"sin esperar, (leer|le[ée])r? ni monitorear")
            self.assertIn(f"pedido explícito de {APROBADOR}", text)
            self.assertRegex(text, r"estado técnico ambiguo")

        contract = (ROOT / "docs/CONTRATO_HANDOFF.md").read_text(encoding="utf-8")
        self.assertIn("no espera, lee ni monitorea la respuesta del sucesor", contract)
        self.assertIn("técnicamente ambigua", contract)

    def test_thread_rescue_skill_handles_duplicate_codex_threads(self):
        for runtime in (".agents", ".claude"):
            text = (ROOT / runtime / "skills/thread-rescue/SKILL.md").read_text(encoding="utf-8")
            self.assertIn("thread roto", text)
            self.assertIn("NOMBRE (2)", text)
            self.assertIn("[roto archivado YYYY-MM-DD]", text)
            self.assertIn("No modificar `OWNERS.md`", text)
            self.assertIn("idempotente", text)
            self.assertIn("más de dos candidatos", text)

        codex = (ROOT / ".agents/skills/thread-rescue/SKILL.md").read_text(encoding="utf-8")
        self.assertIn("set_thread_title", codex)
        self.assertIn("set_thread_archived", codex)
        self.assertIn("$context-resume", codex)

        contract = (ROOT / "docs/CONTRATO_HANDOFF.md").read_text(encoding="utf-8")
        self.assertIn("Rescate de thread roto", contract)
        self.assertIn("no modifica OWNERS", contract)

    def test_worktree_create_renames_current_task_when_possible(self):
        for runtime in (".agents", ".claude"):
            text = (ROOT / runtime / "skills/worktree-create/SKILL.md").read_text(encoding="utf-8")
            self.assertIn("00_[WT]_[NOMBRE]", text)
            self.assertRegex(text, r"herramienta real")
            self.assertRegex(text, r"renombrar(?:lo)?")
            self.assertRegex(text, r"pendiente manual")

        contract = (ROOT / "docs/CONTRATO_HANDOFF.md").read_text(encoding="utf-8")
        self.assertIn("worktree-create", contract)
        self.assertIn("00_[WT]_[NOMBRE]", contract)

    def test_inactive_worktree_chat_is_not_left_as_active(self):
        for runtime in (".agents", ".claude"):
            pause = (ROOT / runtime / "skills/worktree-pause/SKILL.md").read_text(encoding="utf-8")
            transfer = (ROOT / runtime / "skills/worktree-transfer/SKILL.md").read_text(encoding="utf-8")
            for text in (pause, transfer):
                self.assertIn("IN_[WT]_[NOMBRE]", text)
                self.assertIn("00_...", text)
                self.assertRegex(text, r"inactiv[oa]")

        contract = (ROOT / "docs/CONTRATO_HANDOFF.md").read_text(encoding="utf-8")
        self.assertIn("IN_[WT]_[NOMBRE]", contract)
        self.assertIn("No dejarlo como `00_...`", contract)

    def test_worktree_close_archives_as_historical_chat_not_cl_prefix(self):
        for runtime in (".agents", ".claude"):
            text = (ROOT / runtime / "skills/worktree-close/SKILL.md").read_text(encoding="utf-8")
            self.assertIn("XX_[WT]_[VERSIÓN]_[NOMBRE]", text)
            self.assertIn("CL_...", text)
            self.assertRegex(text, r"no usa ni inventa prefijos `CL_")
            self.assertIn("OWNERS.md", text)

        contract = (ROOT / "docs/CONTRATO_HANDOFF.md").read_text(encoding="utf-8")
        self.assertIn("XX_[WT]_[VERSIÓN]_[NOMBRE]", contract)
        self.assertRegex(contract, r"(?i)no existe prefijo `CL_\.\.\.`")

    def test_worktree_close_closes_inactive_total_transfer_cedents(self):
        for runtime in (".agents", ".claude"):
            close = (ROOT / runtime / "skills/worktree-close/SKILL.md").read_text(encoding="utf-8")
            self.assertIn("cedentes asociados", close)
            self.assertIn("cedida total a WTxx; issue #n", close)
            self.assertIn("git status --short", close)
            self.assertRegex(close, r"merge/rebase/cherry-pick")
            self.assertRegex(close, r"pendientes? no transferidos")
            self.assertIn("línea cerrada por receptor WTxx", close)
            self.assertRegex(close, r"No (inferir|infieras)")

            transfer = (ROOT / runtime / "skills/worktree-transfer/SKILL.md").read_text(encoding="utf-8")
            self.assertIn("cedida total a WTxx; issue #n", transfer)
            self.assertRegex(transfer, r"[Uu]na entrega parcial .*no usa esa marca")

        contract = (ROOT / "docs/CONTRATO_HANDOFF.md").read_text(encoding="utf-8")
        self.assertIn("cedida total a WTxx; issue #n", contract)
        self.assertIn("línea cerrada por receptor WTxx", contract)
        self.assertIn("no usa la marca de cesión total", contract)
        self.assertIn("No escribe un handoff nuevo obligatorio del cedente", contract)

    def test_transfer_leaves_receiver_prompt_ready_to_copy(self):
        expected_commands = {".agents": "$worktree-transfer", ".claude": "/worktree-transfer"}
        for runtime, command in expected_commands.items():
            text = (ROOT / runtime / "skills/worktree-transfer/SKILL.md").read_text(encoding="utf-8")
            self.assertIn("Prompt para el receptor", text)
            self.assertIn(command, text)
            self.assertIn("enlace a la Issue", text)
            self.assertIn("WT receptor esperado", text)
            self.assertIn("commits en orden", text)
            self.assertIn("no tocar WT ajenos", text)
            self.assertIn("Destino: Codex", text)
            self.assertIn("Destino: Claude", text)
            self.assertRegex(text, r"confirmaci[oó]n humana")
            self.assertRegex(text, r"listo.*completado.*archivar|listo`, `completado`, `archivar")
            self.assertRegex(text, r"[Nn]o (renombrar|renombres) ni (archivar|archives)")

        contract = (ROOT / "docs/CONTRATO_HANDOFF.md").read_text(encoding="utf-8")
        self.assertIn("Prompt para el receptor", contract)
        self.assertIn("listo para copiar", contract)
        self.assertIn("espera confirmación humana", contract)
        self.assertIn("Codex usa `$worktree-transfer`", contract)
        self.assertIn("Claude usa `/worktree-transfer`", contract)
        self.assertIn("Si se interrumpe antes del archivado", contract)

    def test_transfer_blocks_or_redirects_when_requested_wt_is_not_current_thread(self):
        for runtime in (".agents", ".claude"):
            text = (ROOT / runtime / "skills/worktree-transfer/SKILL.md").read_text(encoding="utf-8")
            self.assertRegex(text, r"WT solicitado como saliente coincide con el WT/thread actual")
            self.assertIn("OWNERS.md", text)
            self.assertIn("HANDOFF.md", text)
            self.assertRegex(text, r"Issues?, títulos ni archivo de chats")
            self.assertRegex(text, r"único thread correcto")
            self.assertRegex(text, r"transferencia debe ejecutarse desde cero en el thread correcto")
            self.assertRegex(text, r"[Nn]o (pedir|pidas) autorización")

        contract = (ROOT / "docs/CONTRATO_HANDOFF.md").read_text(encoding="utf-8")
        self.assertIn("WT solicitado como saliente coincide con el WT/thread actual", contract)
        self.assertIn("No pide autorización para ejecutar una transferencia desde el thread equivocado", contract)
        self.assertIn("La redirección por thread equivocado no ejecuta la transferencia", contract)

    def test_product_prs_do_not_reference_private_coordination(self):
        criteria = (ROOT / "docs/CRITERIOS_ENTREGA_PRODUCTO.md").read_text(encoding="utf-8")
        self.assertIn("Antes de crear o actualizar un PR", criteria)
        self.assertIn("referencias privadas", criteria)
        self.assertIn("owner/repo#n", criteria)
        self.assertIn(f"~/.{ARNES}", criteria)
        self.assertIn("HANDOFF", criteria)
        self.assertIn("WTxx", criteria)
        self.assertIn("contexto del producto", criteria)

        contract = (ROOT / "docs/CONTRATO_HANDOFF.md").read_text(encoding="utf-8")
        self.assertIn("La trazabilidad es asimétrica", contract)
        self.assertIn("Issue privada puede enlazar PRs", contract)
        self.assertIn("un PR, commit, changelog o documentación del producto no debe enlazar", contract)
        self.assertIn("editar el PR del producto", contract)
        self.assertIn("registrar la corrección en la Issue privada", contract)

        for runtime in (".agents", ".claude"):
            text = (ROOT / runtime / "skills/worktree-transfer/SKILL.md").read_text(encoding="utf-8")
            self.assertIn("enlace a la Issue", text)
            self.assertIn("sólo para coordinación interna", text)
            self.assertRegex(text, r"no (copiarlo|lo copies) al cuerpo, título, commits, changelog ni documentación del producto")

        product = "\n".join(
            path.read_text(encoding="utf-8")
            for path in (ROOT / "plantilla-proyecto").rglob("*")
            if path.is_file()
        )
        self.assertNotIn("coordinacion-proyectos", product)
        self.assertNotIn(ARNES, product)
        self.assertNotRegex(product, r"[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+#\d+")

    def test_context_handoff_preserves_only_authorized_ssh_context(self):
        contract = (ROOT / "docs/CONTRATO_HANDOFF.md").read_text(encoding="utf-8")
        for expected in ("Contexto SSH heredable", "SSH_AUTH_SOCK", "Git Bash/MSYS",
                         "PowerShell/OpenSSH", "alias SSH", "ssh-add", "ssh-agent",
                         "passphrases", ".env"):
            self.assertIn(expected, contract)
        self.assertRegex(contract, r"sesión saliente ya usó SSH funcionalmente|usó SSH funcionalmente")
        self.assertRegex(contract, r"No agregar esta sección por rutina")
        self.assertRegex(contract, r"Nunca guardar claves privadas")

        for runtime in (".agents", ".claude"):
            handoff = (ROOT / runtime / "skills/context-handoff/SKILL.md").read_text(encoding="utf-8")
            resume = (ROOT / runtime / "skills/context-resume/SKILL.md").read_text(encoding="utf-8")
            for text in (handoff, resume):
                self.assertIn("contexto SSH heredable", text)
                self.assertIn("alias SSH", text)
                self.assertIn("SSH_AUTH_SOCK", text)
                self.assertIn("Git Bash/MSYS", text)
                self.assertIn("PowerShell/OpenSSH", text)
                self.assertIn("ssh-add", text)
                self.assertIn("ssh-agent", text)
                self.assertIn(".env", text)
                self.assertRegex(text, r"claves privadas")
                self.assertRegex(text, r"passphrases")
            self.assertRegex(handoff, r"Si no se usó SSH")
            self.assertRegex(handoff, r"no agreg")
            self.assertRegex(resume, r"antes de declarar bloqueo de autenticaci")
            self.assertRegex(resume, r"(pedir|pedí) intervención del usuario")

    def test_maintenance_score_registry_is_internal_and_computable(self):
        base = ROOT / "maintenance/score"
        readme = base / "README.md"
        events = base / "events.jsonl"
        script = base / "score.py"
        for path in (readme, events, script):
            self.assertTrue(path.is_file(), str(path))

        readme_text = readme.read_text(encoding="utf-8")
        self.assertIn("no se instala como skill", readme_text)
        self.assertIn("no se copia a productos", readme_text)
        self.assertIn("scores relativos", readme_text)

        loaded = [json.loads(line) for line in events.read_text(encoding="utf-8").splitlines() if line.strip()]
        result = run(sys.executable, script, "--json")
        self.assertEqual(0, result.returncode, result.stderr)
        data = json.loads(result.stdout)
        self.assertEqual(len(loaded), len(data["events"]))
        for event in data["events"]:
            self.assertGreaterEqual(event["passive_score"], 0)
            self.assertGreaterEqual(event["invoked_score"], 0)
            self.assertGreaterEqual(event["savings_score"], 0)

    def test_personal_templates_and_install_contract_exist(self):
        for rel in ("personal/PROJECT.template.md", "personal/OWNERS.template.md",
                    "HANDOFF.template.md", "docs/CONTRATO_HANDOFF.md",
                    "docs/CRITERIOS_ENTREGA_PRODUCTO.md", "docs/INSTALACION.md",
                    "docs/PUBLICACION.md", "scripts/Publicar-Arnes.ps1",
                    "scripts/Instalar-Arnes.ps1",
                    "docs/CODEGRAPH.md", "scripts/Preparar-Proyecto.ps1",
                    "scripts/Generar-CodeGraph.ps1",
                    "scripts/Verificar-Identidad-Git.ps1",
                    "scripts/Iniciar-Sin-Deteccion-De-Agente.ps1",
                    "scripts/Verificar-Artefactos-Agente-Next.ps1"):
            self.assertTrue((ROOT / rel).is_file(), rel)
        owners = (ROOT / "personal/OWNERS.template.md").read_text(encoding="utf-8")
        self.assertFalse(re.search(r"^\|\s*WT\d+\s*\|", owners, re.M),
                         "Una plantilla vacía no debe registrar un WT activo ficticio.")
        project = (ROOT / "personal/PROJECT.template.md").read_text(encoding="utf-8")
        self.assertIn("Identidad Git autorizada", project)
        self.assertIn("user.email", project)
        install = (ROOT / "docs/INSTALACION.md").read_text(encoding="utf-8")
        self.assertIn("diez skills de Codex", install)
        self.assertIn("diez skills de Claude", install)
        self.assertIn("Iniciar-Sin-Deteccion-De-Agente.ps1", install)
        self.assertIn("Verificar-Artefactos-Agente-Next.ps1", install)

    def test_next_agent_rules_documented_in_personal_rules_and_skills(self):
        for rel in ("personal/AGENTS.md", "personal/CLAUDE.md",
                    "docs/CONTRATO_HANDOFF.md", "docs/CRITERIOS_ENTREGA_PRODUCTO.md",
                    ".agents/skills/worktree-transfer/SKILL.md",
                    ".claude/skills/worktree-transfer/SKILL.md"):
            text = (ROOT / rel).read_text(encoding="utf-8")
            self.assertIn("Iniciar-Sin-Deteccion-De-Agente.ps1", text, rel)
            self.assertIn("Verificar-Artefactos-Agente-Next.ps1", text, rel)
        for rel in ("personal/AGENTS.md", "personal/CLAUDE.md",
                    "docs/CONTRATO_HANDOFF.md", "docs/CRITERIOS_ENTREGA_PRODUCTO.md"):
            text = (ROOT / rel).read_text(encoding="utf-8")
            self.assertIn("next-env.d.ts", text, rel)
            self.assertIn(".next/dev/types", text, rel)

    def test_agent_detection_wrapper_removes_env_only_for_child(self):
        fixture = self.destination / "next-agent-wrapper"
        fixture.mkdir()
        probe = fixture / "probe.ps1"
        probe.write_text(
            "Write-Output \"CLAUDE_CODE=$env:CLAUDE_CODE\"\n"
            "Write-Output \"CODEX_THREAD_ID=$env:CODEX_THREAD_ID\"\n"
            "Write-Output \"CURSOR_TEST=$env:CURSOR_TEST\"\n"
            "Write-Output \"COPILOT_TEST=$env:COPILOT_TEST\"\n"
            "Write-Output \"KEEP_ME=$env:KEEP_ME\"\n",
            encoding="utf-8")
        env = os.environ.copy()
        env.update({
            "CLAUDE_CODE": "1",
            "CODEX_THREAD_ID": "2",
            "CURSOR_TEST": "3",
            "COPILOT_TEST": "4",
            "KEEP_ME": "ok",
        })
        result = run(PWSH, "-NoProfile", "-File",
                     ROOT / "scripts/Iniciar-Sin-Deteccion-De-Agente.ps1",
                     PWSH, "-NoProfile", "-File", probe, env=env)
        self.assertEqual(0, result.returncode, result.stderr)
        self.assertIn("CLAUDE_CODE=", result.stdout)
        self.assertIn("CODEX_THREAD_ID=", result.stdout)
        self.assertIn("CURSOR_TEST=", result.stdout)
        self.assertIn("COPILOT_TEST=", result.stdout)
        self.assertIn("KEEP_ME=ok", result.stdout)
        self.assertNotIn("CLAUDE_CODE=1", result.stdout)
        self.assertNotIn("CODEX_THREAD_ID=2", result.stdout)
        self.assertNotIn("CURSOR_TEST=3", result.stdout)
        self.assertNotIn("COPILOT_TEST=4", result.stdout)

    def test_next_agent_artifact_guard_blocks_generated_files(self):
        fixture = self.destination / "next-agent-guard"
        fixture.mkdir()
        self.assertEqual(0, run("git", "init", "-q", "-b", "dev", fixture).returncode)
        frontend = fixture / "frontend"
        frontend.mkdir()
        (frontend / "AGENTS.md").write_text(
            "# Agent rules\n\n<!-- BEGIN:nextjs-agent-rules -->\nGenerado\n",
            encoding="utf-8")
        (frontend / "CLAUDE.md").write_text("@AGENTS.md\n", encoding="utf-8")
        (frontend / "next-env.d.ts").write_text(
            '/// <reference types="./.next/dev/types/routes.d.ts" />\n',
            encoding="utf-8")
        result = run(PWSH, "-NoProfile", "-File",
                     ROOT / "scripts/Verificar-Artefactos-Agente-Next.ps1",
                     "-RepoPath", fixture)
        self.assertNotEqual(0, result.returncode)
        self.assertIn("BEGIN:nextjs-agent-rules", result.stderr)
        self.assertIn("@AGENTS.md", result.stderr)
        self.assertIn(".next/dev/types", result.stderr)

    def test_next_agent_artifact_guard_allows_legitimate_files(self):
        fixture = self.destination / "next-agent-guard-ok"
        fixture.mkdir()
        self.assertEqual(0, run("git", "init", "-q", "-b", "dev", fixture).returncode)
        (fixture / "AGENTS.md").write_text("# Reglas del producto\n", encoding="utf-8")
        (fixture / "CLAUDE.md").write_text("# Claude\n\nUsar las reglas del producto.\n", encoding="utf-8")
        (fixture / "next-env.d.ts").write_text(
            '/// <reference types="./.next/types/routes.d.ts" />\n',
            encoding="utf-8")
        result = run(PWSH, "-NoProfile", "-File",
                     ROOT / "scripts/Verificar-Artefactos-Agente-Next.ps1",
                     "-RepoPath", fixture)
        self.assertEqual(0, result.returncode, result.stderr)

    def test_git_identity_guard_blocks_wrong_noreply_id(self):
        fixture = self.destination / "identity-guard"
        fixture.mkdir()
        self.assertEqual(0, run("git", "init", "-q", "-b", "dev", fixture).returncode)
        self.assertEqual(0, run("git", "-C", fixture, "config", "user.name", "usuario-ejemplo").returncode)
        wrong = "000000000+usuario-ejemplo@users.noreply.github.com"
        expected = "123456789+usuario-ejemplo@users.noreply.github.com"
        self.assertEqual(0, run("git", "-C", fixture, "config", "user.email", wrong).returncode)
        result = run(PWSH, "-NoProfile", "-File", ROOT / "scripts/Verificar-Identidad-Git.ps1",
                     "-RepoPath", fixture, "-ExpectedName", "usuario-ejemplo",
                     "-ExpectedEmail", expected, "-RequireGitHubNoreply")
        self.assertNotEqual(0, result.returncode)
        self.assertIn("Identidad Git inválida", result.stderr)

        self.assertEqual(0, run("git", "-C", fixture, "config", "user.email", expected).returncode)
        (fixture / "README.md").write_text("identity\n", encoding="utf-8")
        self.assertEqual(0, run("git", "-C", fixture, "add", "README.md").returncode)
        self.assertEqual(0, run("git", "-C", fixture, "commit", "-q", "-m", "base").returncode)
        result = run(PWSH, "-NoProfile", "-File", ROOT / "scripts/Verificar-Identidad-Git.ps1",
                     "-RepoPath", fixture, "-ExpectedName", "usuario-ejemplo",
                     "-ExpectedEmail", expected, "-RequireGitHubNoreply",
                     "-RevisionRange", "HEAD")
        self.assertEqual(0, result.returncode, result.stderr)

    def test_codegraph_generates_private_outputs_outside_product(self):
        fixture = self.destination / "codegraph"
        repo = fixture / "repo"
        output = fixture / "private-state/codegraph/WT01"
        repo.mkdir(parents=True)
        self.assertEqual(0, run("git", "init", "-q", "-b", "dev", repo).returncode)
        self.assertEqual(0, run("git", "-C", repo, "config", "user.name", "Test").returncode)
        self.assertEqual(0, run("git", "-C", repo, "config", "user.email", "test@example.invalid").returncode)
        (repo / "package.json").write_text('{"scripts":{"test":"node src/index.js"}}\n', encoding="utf-8")
        (repo / "src").mkdir()
        (repo / "src/util.ts").write_text("export function util() { return 1 }\n", encoding="utf-8")
        (repo / "src/index.ts").write_text("import { util } from './util'\nexport function main() { return util() }\n", encoding="utf-8")
        self.assertEqual(0, run("git", "-C", repo, "add", ".").returncode)
        self.assertEqual(0, run("git", "-C", repo, "commit", "-q", "-m", "base").returncode)

        result = run(PWSH, "-NoProfile", "-File", ROOT / "scripts/Generar-CodeGraph.ps1",
                     "-WTPath", repo, "-OutputRoot", output, "-WT", "WT01")
        self.assertEqual(0, result.returncode, result.stderr)
        self.assertTrue((output / "graph.json").is_file())
        self.assertTrue((output / "resumen.md").is_file())
        self.assertTrue((output / "manifest.md").is_file())
        self.assertFalse((repo / "codegraph").exists())
        graph = json.loads((output / "graph.json").read_text(encoding="utf-8-sig"))
        self.assertEqual("codegraph-v1", graph["schema"])
        paths = {item["path"] for item in graph["files"]}
        self.assertIn("src/index.ts", paths)
        self.assertIn("src/util.ts", paths)
        self.assertTrue(any(edge["from"] == "src/index.ts" and edge["to"] == "src/util.ts"
                            for edge in graph["edges"]))
        summary = (output / "resumen.md").read_text(encoding="utf-8-sig")
        self.assertIn("- source:", summary)
        self.assertIn("- manifest:", summary)

    def test_project_bootstrap_creates_container_layout_and_first_worktree(self):
        fixture = self.destination / "bootstrap"
        seed = fixture / "seed"
        remote = fixture / "origin.git"
        container = fixture / "project"
        seed.mkdir(parents=True)
        container.mkdir()
        self.assertEqual(0, run("git", "init", "-q", "-b", "dev", seed).returncode)
        self.assertEqual(0, run("git", "-C", seed, "config", "user.name", "Test").returncode)
        self.assertEqual(0, run("git", "-C", seed, "config", "user.email", "test@example.invalid").returncode)
        (seed / "README.md").write_text("fixture\n", encoding="utf-8")
        self.assertEqual(0, run("git", "-C", seed, "add", "README.md").returncode)
        self.assertEqual(0, run("git", "-C", seed, "commit", "-q", "-m", "base").returncode)
        prepare_bare_remote(seed, remote)

        result = run(PWSH, "-NoProfile", "-File", ROOT / "scripts/Preparar-Proyecto.ps1",
                     "-Contenedor", container, "-Repositorio", remote, "-Base", "dev",
                     "-IdWT", "WT01", "-Titulo", "Sanitizado R5",
                     "-Rama", "feature/sanitizado/codex/revision-5")
        if result.returncode and "CreateFileMapping" in result.stderr:
            self.skipTest("Git/MSYS local transport no disponible en este entorno")
        self.assertEqual(0, result.returncode, result.stderr)
        repo = container / "repo"
        wt = container / "worktrees/WT01 - Sanitizado R5"
        self.assertTrue((repo / ".git").exists())
        self.assertTrue((wt / ".git").is_file())
        branch = run("git", "-C", wt, "branch", "--show-current")
        self.assertEqual("feature/sanitizado/codex/revision-5", branch.stdout.strip())
        upstream = run("git", "-C", wt, "rev-parse", "--abbrev-ref",
                       "--symbolic-full-name", "@{u}")
        self.assertNotEqual(0, upstream.returncode, upstream.stdout)
        listed = run("git", "-C", repo, "worktree", "list", "--porcelain")
        self.assertIn(str(wt.resolve()).replace("\\", "/"), listed.stdout.replace("\\", "/"))

    @unittest.skipUnless(WINDOWS_POWERSHELL, "Windows PowerShell no disponible")
    def test_project_bootstrap_supports_windows_powershell_51(self):
        fixture = self.destination / "bootstrap-ps51"
        seed = fixture / "seed"
        remote = fixture / "origin.git"
        container = fixture / "project"
        seed.mkdir(parents=True)
        container.mkdir()
        self.assertEqual(0, run("git", "init", "-q", "-b", "dev", seed).returncode)
        self.assertEqual(0, run("git", "-C", seed, "config", "user.name", "Test").returncode)
        self.assertEqual(0, run("git", "-C", seed, "config", "user.email", "test@example.invalid").returncode)
        (seed / "README.md").write_text("fixture\n", encoding="utf-8")
        self.assertEqual(0, run("git", "-C", seed, "add", "README.md").returncode)
        self.assertEqual(0, run("git", "-C", seed, "commit", "-q", "-m", "base").returncode)
        prepare_bare_remote(seed, remote)

        result = run(WINDOWS_POWERSHELL, "-NoProfile", "-File", ROOT / "scripts/Preparar-Proyecto.ps1",
                     "-Contenedor", container, "-Repositorio", remote, "-Base", "dev",
                     "-IdWT", "WT01", "-Titulo", "PS51",
                     "-Rama", "feature/bootstrap/ps51")
        if result.returncode and "CreateFileMapping" in result.stderr:
            self.skipTest("Git/MSYS local transport no disponible en este entorno")
        self.assertEqual(0, result.returncode, result.stderr)
        wt = container / "worktrees/WT01 - PS51"
        upstream = run("git", "-C", wt, "rev-parse", "--abbrev-ref",
                       "--symbolic-full-name", "@{u}")
        self.assertNotEqual(0, upstream.returncode, upstream.stdout)

    def test_publish_creates_clean_repo_and_install_only_installs(self):
        fixture = self.destination / "publicacion"
        source = fixture / "harness-origen"
        published = fixture / "arnes-empresa"
        home = fixture / "home"
        shutil.copytree(ROOT, source, ignore=shutil.ignore_patterns(
            ".git", "__pycache__", "instalacion.json", "settings.local.json"))
        self.assertEqual(0, run("git", "init", "-q", "-b", "dev", source).returncode)
        self.assertEqual(0, run("git", "-C", source, "config", "user.name", "Base").returncode)
        self.assertEqual(0, run("git", "-C", source, "config", "user.email", "base@example.invalid").returncode)
        self.assertEqual(0, run("git", "-C", source, "add", "-A").returncode)
        self.assertEqual(0, run("git", "-C", source, "commit", "-q", "-m", "base").returncode)
        self.assertEqual(0, run("git", "-C", source, "remote", "add", "origin",
                                "https://github.com/autor-ejemplo/arnes-origen.git").returncode)
        marker = "{{" + "APROBADOR" + "}}"
        if marker not in (source / "personal/AGENTS.md").read_text(encoding="utf-8"):
            self.skipTest("El repo ya fue publicado; la prueba necesita los marcadores originales")
        source_head = run("git", "-C", source, "rev-parse", "HEAD").stdout
        email = "123+empresa-ejemplo@users.noreply.github.com"
        publish = (PWSH, "-NoProfile", "-File", source / "scripts/Publicar-Arnes.ps1",
                   "-Si", "-SinPublicar", "-SinCoordinacion", "-Destino", published)
        install = (PWSH, "-NoProfile", "-File", published / "scripts/Instalar-Arnes.ps1", "-Inicio", home)

        # Instalar sobre un clon sin publicar falla sin tocar nada.
        result = run(PWSH, "-NoProfile", "-File", source / "scripts/Instalar-Arnes.ps1", "-Inicio", home)
        self.assertNotEqual(0, result.returncode)
        self.assertIn("Publicar-Arnes.ps1", result.stderr)
        self.assertFalse(home.exists())

        # Publicar sin datos y con -Si falla sin crear el destino.
        result = run(*publish)
        self.assertNotEqual(0, result.returncode)
        self.assertFalse(published.exists())

        result = run(*publish, "-Aprobador", "Ana", "-Cuenta", "empresa-ejemplo", "-Email", email,
                     "-Arnes", "arnes-empresa")
        self.assertEqual(0, result.returncode, result.stderr)
        # El clon de origen queda intacto.
        self.assertEqual(source_head, run("git", "-C", source, "rev-parse", "HEAD").stdout)
        self.assertEqual("", run("git", "-C", source, "status", "--porcelain").stdout)
        self.assertFalse((source / "instalacion.json").exists())
        # El repo publicado empieza con un único commit, en main y dev, sin remoto.
        config = json.loads((published / "instalacion.json").read_text(encoding="utf-8"))
        self.assertEqual({"aprobador": "Ana", "cuenta_github": "empresa-ejemplo", "email": email,
                          "arnes": "arnes-empresa", "coordinacion": "empresa-ejemplo/SharedCord"}, config)
        self.assertEqual("1", run("git", "-C", published, "rev-list", "--count", "--all").stdout.strip())
        self.assertEqual(run("git", "-C", published, "rev-parse", "main").stdout,
                         run("git", "-C", published, "rev-parse", "dev").stdout)
        self.assertEqual("dev", run("git", "-C", published, "branch", "--show-current").stdout.strip())
        self.assertEqual("", run("git", "-C", published, "remote").stdout)
        self.assertEqual("", run("git", "-C", published, "status", "--porcelain").stdout)
        log = run("git", "-C", published, "log", "-1", "--format=%an %ae%n%s")
        self.assertEqual(f"empresa-ejemplo {email}\nArnés para Codex y Claude Code", log.stdout.strip())
        pending = run("git", "-C", published, "grep", "-l", "-F", "{{", "--", ".",
                      ":!scripts/Publicar-Arnes.ps1", ":!scripts/Instalar-Arnes.ps1",
                      ":!scripts/verificar_plantillas.py")
        self.assertEqual("", pending.stdout)
        self.assertIn("Ana", (published / "personal/AGENTS.md").read_text(encoding="utf-8"))
        self.assertIn("~/.arnes-empresa/", (published / "docs/CRITERIOS_ENTREGA_PRODUCTO.md").read_text(encoding="utf-8"))
        project = (published / "personal/PROJECT.template.md").read_text(encoding="utf-8")
        self.assertIn("empresa-ejemplo/SharedCord", project)
        self.assertIn(email, project)
        self.assertIn("Copyright", (published / "README.md").read_text(encoding="utf-8").splitlines()[2])
        for name in ("LICENSE", "NOTICE", "PROVENANCE.md", "scripts/Publicar-Arnes.ps1",
                     "scripts/Instalar-Arnes.ps1"):
            self.assertEqual((source / name).read_bytes(), (published / name).read_bytes(), name)

        # Publicar de nuevo sobre el mismo destino se niega.
        result = run(*publish, "-Aprobador", "Ana", "-Cuenta", "empresa-ejemplo", "-Email", email,
                     "-Arnes", "arnes-empresa")
        self.assertNotEqual(0, result.returncode)

        # Instalar sólo instala: no pregunta ni modifica el repo.
        result = run(*install)
        self.assertEqual(0, result.returncode, result.stderr)
        self.assertEqual("1", run("git", "-C", published, "rev-list", "--count", "HEAD").stdout.strip())
        self.assertEqual("", run("git", "-C", published, "status", "--porcelain").stdout)
        self.assertTrue((home / ".claude/skills/context-resume/SKILL.md").is_file())
        self.assertTrue((home / ".agents/skills/context-resume/SKILL.md").is_file())
        self.assertTrue((home / ".arnes-empresa/scripts/Preparar-Proyecto.ps1").is_file())
        self.assertTrue((home / ".arnes-empresa/templates/PROJECT.template.md").is_file())
        self.assertTrue((home / ".arnes-empresa/INSTALACION.md").is_file())
        agents = (home / ".codex/AGENTS.md").read_text(encoding="utf-8")
        self.assertEqual(1, agents.count("<!-- inicio: arnes-empresa -->"))
        self.assertIn("Ana", agents)

        (home / ".codex/AGENTS.md").write_text("Reglas propias\n\n" + agents, encoding="utf-8")
        result = run(*install)
        self.assertEqual(0, result.returncode, result.stderr)
        agents = (home / ".codex/AGENTS.md").read_text(encoding="utf-8")
        self.assertTrue(agents.startswith("Reglas propias"))
        self.assertEqual(1, agents.count("<!-- inicio: arnes-empresa -->"))

        # Reconfigurar desde el repo publicado: sin cambios no commitea; con cambios, un commit.
        reconfigure = (PWSH, "-NoProfile", "-File", published / "scripts/Publicar-Arnes.ps1",
                       "-Si", "-SinCoordinacion")
        result = run(*reconfigure)
        self.assertEqual(0, result.returncode, result.stderr)
        self.assertIn("no se reescribió", result.stdout)
        self.assertEqual("1", run("git", "-C", published, "rev-list", "--count", "HEAD").stdout.strip())
        result = run(*reconfigure, "-Aprobador", "Beatriz")
        self.assertEqual(0, result.returncode, result.stderr)
        self.assertEqual("2", run("git", "-C", published, "rev-list", "--count", "HEAD").stdout.strip())
        self.assertEqual("", run("git", "-C", published, "status", "--porcelain").stdout)
        rules = (published / "personal/AGENTS.md").read_text(encoding="utf-8")
        self.assertIn("Beatriz", rules)
        self.assertNotRegex(rules, r"\bAna\b")
        self.assertEqual("Beatriz", json.loads(
            (published / "instalacion.json").read_text(encoding="utf-8"))["aprobador"])

    def test_powershell_scripts_avoid_dotnet_core_getfullpath_overload(self):
        for script in ("Preparar-Proyecto.ps1", "Preparar-Plantilla.ps1", "Instalar-Arnes.ps1",
                       "Publicar-Arnes.ps1"):
            text = (ROOT / "scripts" / script).read_text(encoding="utf-8")
            self.assertNotRegex(text, r"GetFullPath\([^,\r\n]+,\s*\(")

    def test_project_bootstrap_refuses_nonempty_container(self):
        container = self.destination / "occupied-project"
        container.mkdir()
        marker = container / "keep.txt"
        marker.write_text("keep", encoding="utf-8")
        result = run(PWSH, "-NoProfile", "-File", ROOT / "scripts/Preparar-Proyecto.ps1",
                     "-Contenedor", container, "-Repositorio", "unused", "-Base", "dev",
                     "-IdWT", "WT01", "-Titulo", "Inicio", "-Rama", "feature/inicio")
        self.assertNotEqual(0, result.returncode)
        self.assertEqual("keep", marker.read_text(encoding="utf-8"))
        self.assertEqual({"keep.txt"}, set(contents(container)))


if __name__ == "__main__":
    unittest.main(verbosity=2)
