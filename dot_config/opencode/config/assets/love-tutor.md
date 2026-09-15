# Love Tutor profile

Install all seven Love Tutor skills into a project's `.opencode/skills/`:

```powershell
& "$HOME/.config/opencode/scripts/opencode-assets.ps1" apply -Profiles love-tutor -Scope project -ProjectRoot "D:/Projects/my-project"
```

Replace the project path with an existing project directory. Use `plan` instead of `apply` to preview installation. The interactive manager also lists the `love-tutor` profile.

## Included assets

- dating-master-skill
- hinge-profile-optimizer
- love-advise-skill
- love-skill
- partner-skill (including its two example partner profiles)
- relationship-training-skill
- simp-skill

The bundle includes references, prompts, tools, documentation, licenses and examples from the project snapshot. Git metadata, platform metadata and caches are excluded. The original project remains independent; edits there are not automatically synchronized into this snapshot.

This profile installs skills only. The Love Tutor project's `AGENTS.md` and `source/summaries/` knowledge library are separate and are not included. Python dependencies declared by individual skills are not automatically installed.

The asset manager refuses to overwrite existing unmanaged skill paths. Use a project without these skill directories for first installation. Do not remove existing project skills merely to bypass that protection.

The portable source of truth is chezmoi's `dot_config/opencode/config/assets/skills/`. Apply the catalog and asset directories through chezmoi on another managed machine before using this profile. Restart OpenCode after installing skills.
