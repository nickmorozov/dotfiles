# DDT4All Project Memory

## Key Facts
- Pure Python PyQt5 automotive diagnostic tool, ~12k lines of core code
- No test suite — CI just runs `python main.py -git_test` (smoke test)
- No linting/formatting config
- Global state pattern via `options` module (module-level globals)
- Two git submodules: `ddtplugins/` and `ecus/` — need `--recursive` clone
- ECU database is XML/JSON/ZIP, `json/` and `ecus/` dirs are gitignored
- `elm.py` implements full ISO-TP protocol stack from scratch (no external OBD libs)
- Thread safety: `threading.Lock()` in elm.py, QThread in sniffer.py
- Config persists to `ddt4all_data/config.json` (also gitignored)

## Development Patterns
- i18n: `_ = options.translator('ddt4all')` at top of each module
- Device profiles defined in both `options.get_device_settings()` and `elm.DeviceManager`
- `promode` flag gates dangerous ECU write operations
- WebEngine optional with graceful fallback
