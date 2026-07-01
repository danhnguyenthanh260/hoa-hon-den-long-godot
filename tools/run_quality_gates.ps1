param(
    [string]$GodotPath = '.\tools\Godot_v4.5-stable_win64_console.exe',
    [switch]$SkipFlow
)

$ErrorActionPreference = 'Stop'

function Run-Gate([string]$Name, [scriptblock]$Command) {
    Write-Output "GATE START: $Name"
    $global:LASTEXITCODE = 0
    & $Command
    $commandSucceeded = $?
    $exitCode = $global:LASTEXITCODE
    if (-not $commandSucceeded -or $exitCode -ne 0) {
        throw "GATE FAILED: $Name (exit $exitCode)"
    }
    Write-Output "GATE PASS: $Name"
}

if (-not (Test-Path -LiteralPath $GodotPath -PathType Leaf)) {
    throw "Godot console binary not found: $GodotPath"
}

Run-Gate 'reference provenance' {
    & .\tools\validate_reference_library.ps1 -Root .\reference-library -RequireReviewed
}

Run-Gate 'narrative state' {
    & $GodotPath --headless --path . --script res://scripts/tests/test_narrative_state.gd
}

Run-Gate 'checkpoint service' {
    & $GodotPath --headless --path . --script res://scripts/tests/test_checkpoint_service.gd
}

Run-Gate 'dialogue choice signal' {
    & $GodotPath --headless --path . --script res://scripts/tests/test_dialogue_choice_signal.gd
}

Run-Gate 'voice director' {
    & $GodotPath --headless --path . --script res://scripts/tests/test_voice_director.gd
}

Run-Gate 'memory stall inspect UI' {
    & $GodotPath --headless --path . --script res://scripts/tests/test_memory_stall_inspect_ui.gd
}

Run-Gate 'bird stencil puzzle' {
    & $GodotPath --headless --path . --script res://scripts/tests/test_bird_stencil_puzzle.gd
}

Run-Gate 'memorial tablet UI' {
    & $GodotPath --headless --path . --script res://scripts/tests/test_memorial_tablet_ui.gd
}

Run-Gate 'reflection pool' {
    & $GodotPath --headless --path . --script res://scripts/tests/test_reflection_pool.gd
}

Run-Gate 'C2 well contradiction' {
    & $GodotPath --headless --path . --script res://scripts/tests/test_c2_well_contradiction.gd
}

Run-Gate 'chapter 1 progression locks' {
    & $GodotPath --headless --path . --script res://scripts/tests/test_c1_progression.gd
}

Run-Gate 'player shadow policy' {
    & $GodotPath --headless --path . --script res://scripts/tests/test_player_shadow_policy.gd
}

Run-Gate 'Godot import and script parse' {
    & $GodotPath --headless --path . --editor --quit
}

if (-not $SkipFlow) {
    Run-Gate 'five-chapter handler smoke flow' {
        & $GodotPath --headless --path . -- --flow
    }
}

Write-Output 'QUALITY GATES OK'
