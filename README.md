# lex-frame-semantics

Frame semantics modeling for the LegionIO brain-modeled cognitive architecture.

## What It Does

Manages a library of semantic frames — structured knowledge schemas that provide background understanding for concepts and events. When a concept arrives, matching frames are activated and their role slots (agent, patient, instrument, goal, etc.) are filled from context. Detects conflicts when simultaneously active frames assign contradictory values to the same role.

Based on Fillmore's frame semantics theory.

## Usage

```ruby
client = Legion::Extensions::FrameSemantics::Client.new

# Define a semantic frame
client.define_frame(
  name: 'RequestHandling',
  frame_type: :event,
  roles: [:agent, :patient, :instrument, :goal],
  triggers: ['request', 'handle', 'process']
)
# => { success: true, frame_id: "...", name: 'RequestHandling', roles: [...], trigger_count: 3 }

# Activate frames when a concept arrives
client.activate_frame(trigger: 'request', context: { domain: :networking })
# => { activated_frames: [{ frame: 'RequestHandling', activation_strength: 0.8 }],
#      count: 1, primary_frame: 'RequestHandling' }

# Fill role slots with context information
client.fill_role(frame_activation_id: '...', role: :agent, filler: 'http-handler')
client.fill_role(frame_activation_id: '...', role: :goal, filler: 'return JSON response')

# Check role completion
client.role_completion(frame_activation_id: '...')
# => { filled_roles: [:agent, :goal], empty_roles: [:patient, :instrument],
#      coverage: 0.5, coverage_label: :partial }

# Detect conflicting frame activations
client.detect_frame_conflicts
# => { conflicts: [], conflict_count: 0 }

# Most strongly activated frames
client.active_frames
# => { frames: [...sorted by activation_strength], count: 2 }

# Periodic maintenance
client.update_frame_semantics
```

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT
