# lex-frame-semantics

**Level 3 Documentation** — Parent: `/Users/miverso2/rubymine/legion/extensions-agentic/CLAUDE.md`

## Purpose

Frame semantics modeling for the LegionIO cognitive architecture. Implements Fillmore's frame semantics theory — the idea that words and concepts only make sense in terms of the conceptual frames they evoke. Manages a library of semantic frames (structured knowledge schemas), activates frames in response to input concepts, fills frame roles from context, and detects when concepts conflict across activated frames. Provides the agent with structured background knowledge for language understanding and reasoning.

## Gem Info

- **Gem name**: `lex-frame-semantics`
- **Version**: `0.1.0`
- **Namespace**: `Legion::Extensions::FrameSemantics`
- **Location**: `extensions-agentic/lex-frame-semantics/`

## File Structure

```
lib/legion/extensions/frame_semantics/
  frame_semantics.rb            # Top-level requires
  version.rb                    # VERSION = '0.1.0'
  client.rb                     # Client class
  helpers/
    constants.rb                # FRAME_TYPES, ROLE_TYPES, ACTIVATION_LABELS, thresholds
    semantic_frame.rb           # SemanticFrame value object with roles and fillers
    frame_activation.rb         # FrameActivation: tracks active frame instance with role fillers
    frame_engine.rb             # Engine: frame library, activation, role filling, conflict detection
  runners/
    frame_semantics.rb          # Runner module: all public methods
```

## Key Constants

| Constant | Value | Purpose |
|---|---|---|
| `FRAME_TYPES` | `[:event, :state, :relation, :entity, :process, :causal]` | Semantic frame categories |
| `ROLE_TYPES` | `[:agent, :patient, :instrument, :location, :goal, :source, :cause, :result]` | Frame role slots |
| `ACTIVATION_THRESHOLD` | 0.4 | Minimum activation strength to consider a frame active |
| `ACTIVATION_DECAY` | 0.03 | Frame activation strength lost per cycle |
| `MAX_FRAMES` | 100 | Frame library cap |
| `MAX_ACTIVATIONS` | 200 | Concurrent activation cap |
| `CONFLICT_DETECTION_THRESHOLD` | 0.3 | Role filler divergence above which frame conflict is flagged |
| `ACTIVATION_LABELS` | range hash | `strongly_active / active / weakly_active / background / inactive` |
| `ROLE_COVERAGE_LABELS` | range hash | `complete / substantial / partial / sparse` |

## Runners

All methods in `Legion::Extensions::FrameSemantics::Runners::FrameSemantics`.

| Method | Key Args | Returns |
|---|---|---|
| `define_frame` | `name:, frame_type:, roles: [], triggers: []` | `{ success:, frame_id:, name:, roles:, trigger_count: }` |
| `activate_frame` | `trigger:, context: {}` | `{ success:, activated_frames:, count:, primary_frame: }` |
| `fill_role` | `frame_activation_id:, role:, filler:` | `{ success:, frame_activation_id:, role:, filler:, coverage: }` |
| `detect_frame_conflicts` | — | `{ success:, conflicts:, conflict_count: }` |
| `active_frames` | — | `{ success:, frames:, count: }` (sorted by activation strength) |
| `frame_for_concept` | `concept:` | `{ success:, frames:, count: }` (frames triggered by concept) |
| `role_completion` | `frame_activation_id:` | `{ success:, filled_roles:, empty_roles:, coverage:, coverage_label: }` |
| `most_active_frames` | `limit: 5` | `{ success:, frames:, count: }` |
| `update_frame_semantics` | — | `{ success:, decayed_count:, deactivated_count: }` |
| `frame_semantics_stats` | — | Full stats hash |

## Helpers

### `SemanticFrame`
Frame schema definition. Attributes: `id`, `name`, `frame_type`, `roles` (array of role symbols), `triggers` (array of concept strings), `created_at`, `use_count`. `to_h`.

### `FrameActivation`
Active frame instance with role fillers. Attributes: `id`, `frame_id`, `frame_name`, `activation_strength`, `role_fillers` (hash by role), `context`, `activated_at`. Key methods: `fill_role!(role:, filler:)`, `coverage` (filled / total roles), `active?` (strength > `ACTIVATION_THRESHOLD`), `decay!`, `to_h`.

### `FrameEngine`
Central store: `@frames` (hash by id), `@activations` (hash by id), `@frame_index` (hash by trigger -> frame_ids). Key methods:
- `define(name:, frame_type:, roles:, triggers:)`: creates SemanticFrame, indexes by all triggers
- `activate(trigger:, context:)`: finds frames matching trigger, creates FrameActivation instances, sets initial activation strength from context relevance
- `fill(activation_id:, role:, filler:)`: validates role exists in frame schema, sets filler
- `detect_conflicts`: compares role fillers across simultaneously active frames for same-role contradictions
- `decay_all`: calls `decay!` on all activations, removes those below activation floor

## Integration Points

- `activate_frame` called from lex-tick's `sensory_processing` phase when input concepts arrive
- `active_frames` provides structured context for lex-prediction's forward model (frame = event schema)
- `detect_frame_conflicts` feeds lex-dissonance when conflicting conceptual frames are simultaneously active
- `role_completion` informs lex-epistemic-curiosity's gap detection (empty roles = knowledge gaps)
- `frame_for_concept` supports lex-memory retrieval by providing concept-to-schema mappings

## Development Notes

- Frame triggers are string matches (exact or substring), not semantic similarity
- Multiple frames can activate simultaneously from a single trigger — all are returned from `activate_frame`
- Activation strength is set at activation time from context richness, then decays passively
- Frame conflicts detected by checking if same role is filled with contradictory values across active frames
- `define_frame` triggers are stored in a flat index — broad triggers (common words) will match many frames
