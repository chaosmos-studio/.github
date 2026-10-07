# Contributing

Thank you for wanting to help.
The code of our games is private, so most help comes from playing them.

## Ways to help

- **Report a bug.** Use the form on the game's support page, or write to [hello@chaosmos.studio](mailto:hello@chaosmos.studio).
  Say which game, its version (at the bottom of the game's Settings), your phone or browser, and what you did before it went wrong.
- **Tell us about a level that felt wrong.** Every level is generated, so one that feels unfair or too easy for where it sits is a real bug.
- **Share an idea or a solve** on [r/chaosmos_studios](https://www.reddit.com/r/chaosmos_studios/).
- **Help translate.** If you speak Hindi, Indonesian, Brazilian Portuguese or Spanish, write to us.
- **Rate the games** on Google Play and tell a friend. For a small studio, that helps more than anything.

## If you have access to a repository

- **Commits:** one line in plain English that describes the change.
  No body, no prefixes such as `feat:`, no emojis and no trailer lines.
  One commit per logical change.
- **Code:** match the code around it.
  Type everything in GDScript.
  Comment only a non-obvious why.
- **Tests:** run the full suite before pushing, with `godot --headless --path . -s res://tests/run_tests.gd`.
- **Docs:** one sentence per line, no hard wrapping.
- **Pull requests:** the title reads like a commit.
  The description says only what the diff can't show.

To report a security problem, follow the [security policy](SECURITY.md) instead.
