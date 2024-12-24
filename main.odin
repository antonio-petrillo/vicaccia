package game
// Hey, il codice è un pò una monnezza, ma avevo poco tempo e non credo che dopo il 2025 questo codice non verrà mai più utilizzato, quindi nun scassa le palle

import rl "vendor:raylib"

WIDTH :: 1920
HEIGHT :: 1080
TITLE :: "Mario Equense"
FPS :: 60
GRAVITY :: 2000
SPEED :: 500
JUMP :: -800
BRICK_HEIGHT :: 640.0

secret_help :: "https://www.youtube.com/watch?v=dQw4w9WgXcQ"

draw_background :: proc(background, tile: rl.Texture2D) {
    rl.ClearBackground(rl.BLUE)

    shift := rl.Vector2{f32(tile.width * 3), 0.0}
    pos := rl.Vector2{0.0, f32(HEIGHT - tile.height * 3)}
    for i :i32= 0; i <= WIDTH / tile.width; i+=1 {
        rl.DrawTextureEx(tile, pos, 0, 3, rl.WHITE)
        pos += shift
    }

    pos = rl.Vector2{0.0, f32(HEIGHT - tile.height * 3 - background.height * 2)}
    shift = rl.Vector2{f32(background.width * 2), 0.0}
    for i :i32= 0; i <= WIDTH / background.width; i += 1 {
        rl.DrawTextureEx(background, pos, 0, 2, rl.WHITE)
        pos += shift
    }
}

draw_instructions :: proc(font: rl.Font) {
    INSTRUCTIONS_1 :: "Sinistra: freccia sinistra\n\nDestra: freccia destra"
    pos := rl.Vector2{10, 980}
    rl.DrawTextEx(font, INSTRUCTIONS_1, pos, 30, 1,  rl.BLACK)

    INSTRUCTIONS_2 :: "Play/Stop musica: M\n\nEsci: ESC"
    pos2 := rl.Vector2{650, 980}
    rl.DrawTextEx(font, INSTRUCTIONS_2, pos2, 30, 1,  rl.BLACK)

    INSTRUCTIONS_3 :: "Salta: Spazio"
    pos3 := rl.Vector2{1200, 980}
    rl.DrawTextEx(font, INSTRUCTIONS_3, pos3, 30, 1,  rl.BLACK)	

}

Anim :: enum {
    Idle,
    Running,
    Jumping,
}

Facing :: enum {
    Left,
    Right
}

Player :: struct {
    pos: rl.Vector2,
    is_grounded: bool,
    texture_idle: rl.Texture2D,
    texture_jump: rl.Texture2D,
    num_frames: int,
    curr_frame: int,
    anim_timer: f32,
    frame_len: f32,
    texture_running: rl.Texture2D,
    anim: Anim,
    facing: Facing,
}

Brick :: struct {
    rect: rl.Rectangle,
    texture: rl.Texture2D,
    is_hit: bool,
    next_sound: int,
    sounds: []rl.Sound,
    hitten: bool,
}

draw_player :: proc(p: ^Player) {
    if !p.is_grounded {
       p.anim = .Jumping
    }
    switch p.anim {
    case .Idle:
        rl.DrawTextureEx(p.texture_idle, p.pos, 0, 3, rl.WHITE)
    case .Running:
        width := f32(p.texture_running.width) / f32(p.num_frames)

        source := rl.Rectangle{
            x = width * f32(p.curr_frame),
            y = 0,
            width = width * (-1 if p.facing == .Left else 1),
            height = f32(p.texture_running.height),
        }

        dest := rl.Rectangle {
            x = p.pos.x,
            y = p.pos.y,
            width = f32(width * 3),
            height = f32(p.texture_running.height * 3),
        }

        rl.DrawTexturePro(p.texture_running, source, dest, 0, 0, rl.WHITE)

    case .Jumping:
        source := rl.Rectangle{
            x = 0,
            y = 0,
            width = f32(p.texture_jump.width * (-1 if p.facing == .Left else 1)),
            height = f32(p.texture_jump.height),
        }

        dest := rl.Rectangle {
            x = p.pos.x,
            y = p.pos.y,
            width = f32(p.texture_jump.width * 3),
            height = f32(p.texture_jump.height * 3),
        }

        rl.DrawTexturePro(p.texture_jump, source, dest, 0, 0, rl.WHITE)
    }
}

bounds_checks :: proc(p: ^Player, ground: f32, b1, b2: ^Brick) {
    if p.pos.y > ground {
        p.pos.y = ground
        p.is_grounded = true
        b1.is_hit = false
        b2.is_hit = false
    }
    if p.pos.x < 0 {
        p.pos.x = 0
    }
    right_wall := f32(WIDTH - p.texture_idle.width * 3)
    if p.pos.x > right_wall {
       p.pos.x = right_wall
    }
}

draw_bricks :: proc(b1, b2: ^Brick) {
    pos1 := rl.Vector2{f32(b1.rect.x), f32(b1.rect.y)}
    if b1.hitten {
        rl.DrawTextureEx(b1.texture, pos1, 0, 4, rl.WHITE)
    } else {
        rl.DrawRectangleRec(b1.rect, rl.Color{0xff, 0xff, 0xff, 0x00})
    }
    pos2 := rl.Vector2{f32(b2.rect.x), f32(b2.rect.y)}
    if b2.hitten {
        rl.DrawTextureEx(b2.texture, pos2, 0, 4, rl.WHITE)
    } else {
        rl.DrawRectangleRec(b2.rect, rl.Color{0xff, 0xff, 0xff, 0x00})
    }
}

check_collision :: proc(p: ^Player, b: ^Brick) {
    player_collider := rl.Rectangle{
        x = p.pos.x,
        y = p.pos.y,
        width = f32(p.texture_idle.width) * 3,
        height = f32(p.texture_idle.height) * 3,
    }

    if rl.CheckCollisionRecs(player_collider, b.rect) {
        b.rect.y -= 0.5
        b.hitten = true
        if !b.is_hit {
            b.is_hit = true
            idx := (b.next_sound + 1) % len(b.sounds)
            b.next_sound = idx
            rl.PlaySound(b.sounds[idx])
        }
    } else {
        b.rect.y = BRICK_HEIGHT
    }
}

check_collisions :: proc(p: ^Player, b1,b2: ^Brick) {
    check_collision(p, b1)
    check_collision(p, b2)
}

main :: proc() {
    _ = secret_help

    rl.InitWindow(WIDTH, HEIGHT, TITLE)
    defer rl.CloseWindow()

    rl.InitAudioDevice()
    defer rl.CloseAudioDevice()

    background := rl.LoadTexture("./assets/background_with_clouds.png")
    tile := rl.LoadTexture("./assets/tile.png")
    mario_idle := rl.LoadTexture("./assets/mario_idle.png")
    mario_run := rl.LoadTexture("./assets/mario_run.png")
    mario_jump := rl.LoadTexture("./assets/mario_jump.png")
    f_brick := rl.LoadTexture("./assets/f_texture.png")
    d_brick := rl.LoadTexture("./assets/d_texture.png")
    font := rl.LoadFont("./assets/font.ttf")

    sound := rl.LoadSound("./assets/mario_bros.mp3")

    sound_10b65cbedc77698ea5a819e16e3923f0 := rl.LoadSound("./assets/10b65cbedc77698ea5a819e16e3923f0.wav")
    sound_8d58e08c7cd7930ca39b7ea1cb8f006f := rl.LoadSound("./assets/8d58e08c7cd7930ca39b7ea1cb8f006f.wav")
    sound_f7557baefd7f250a42d4127de7b03543 := rl.LoadSound("./assets/f7557baefd7f250a42d4127de7b03543.wav")
    sound_7b14223b18ea183e016de807d0299672 := rl.LoadSound("./assets/7b14223b18ea183e016de807d0299672.wav")
    sound_16c1adaf1533950f7708ac5c6593b9d9 := rl.LoadSound("./assets/16c1adaf1533950f7708ac5c6593b9d9.wav")

    sound_9d9682bcf7204b74fc44957d65cfee03 := rl.LoadSound("./assets/9d9682bcf7204b74fc44957d65cfee03.wav")
    sound_8103446b935314fd8a8d24a141c82ad8 := rl.LoadSound("./assets/8103446b935314fd8a8d24a141c82ad8.wav")

    ground := f32(HEIGHT - tile.height * 3 - mario_idle.height * 3)
    mario_velocity: rl.Vector2

    mario := Player {
        texture_jump = mario_jump,
        texture_running = mario_run,
        texture_idle = mario_idle,
        pos = rl.Vector2{f32(WIDTH / 6), ground},
        frame_len = 0.1,
        anim_timer = 0,
        num_frames = 2,
        curr_frame = 0,
    }

    s1 := [?]rl.Sound{sound_16c1adaf1533950f7708ac5c6593b9d9, sound_7b14223b18ea183e016de807d0299672, sound_f7557baefd7f250a42d4127de7b03543}
    s2 := [?]rl.Sound{sound_16c1adaf1533950f7708ac5c6593b9d9, sound_7b14223b18ea183e016de807d0299672, sound_f7557baefd7f250a42d4127de7b03543, sound_8d58e08c7cd7930ca39b7ea1cb8f006f, sound_10b65cbedc77698ea5a819e16e3923f0, sound_9d9682bcf7204b74fc44957d65cfee03, sound_8103446b935314fd8a8d24a141c82ad8}

    brickF := Brick{
        texture = f_brick,
        rect = rl.Rectangle{
            x = f32(WIDTH) / 3.0,
            y = BRICK_HEIGHT,
            width = f32(f_brick.width) * 4,
            height = f32(f_brick.height) * 4,
        },
        next_sound = -1,
        sounds = s1[:],
    }

    brickD := Brick{
        texture = d_brick,
        rect = rl.Rectangle{
            x = f32(WIDTH) / 3.0 * 2.0,
            y = BRICK_HEIGHT,
            width = f32(d_brick.width) * 4,
            height = f32(d_brick.height) * 4,
        },
        next_sound = -1,
        sounds = s2[:],
    }

    defer {
        rl.UnloadTexture(background)
        rl.UnloadTexture(tile)
        rl.UnloadTexture(mario_idle)
        rl.UnloadTexture(mario_run)
        rl.UnloadTexture(mario_jump)
        rl.UnloadTexture(f_brick)
        rl.UnloadTexture(d_brick)

        rl.UnloadFont(font)

        rl.UnloadSound(sound)
        rl.UnloadSound(sound_10b65cbedc77698ea5a819e16e3923f0)
        rl.UnloadSound(sound_8d58e08c7cd7930ca39b7ea1cb8f006f)
        rl.UnloadSound(sound_f7557baefd7f250a42d4127de7b03543)
        rl.UnloadSound(sound_7b14223b18ea183e016de807d0299672)
        rl.UnloadSound(sound_16c1adaf1533950f7708ac5c6593b9d9)
        rl.UnloadSound(sound_9d9682bcf7204b74fc44957d65cfee03)
        rl.UnloadSound(sound_8103446b935314fd8a8d24a141c82ad8)
    }

    rl.SetTargetFPS(FPS)

    play_music := true
    for !rl.WindowShouldClose() {

        if play_music && !rl.IsSoundPlaying(sound) {
            rl.PlaySound(sound)
        }

        if !play_music && rl.IsSoundPlaying(sound) {
            rl.StopSound(sound)
        }

        rl.BeginDrawing()
        defer {
            draw_instructions(font)
            rl.EndDrawing()
        }


        if rl.IsKeyDown(.LEFT) || rl.IsKeyDown(.H) {
            mario_velocity.x = -SPEED
            mario.anim = .Running
            mario.facing = .Left
        } else if rl.IsKeyDown(.RIGHT) || rl.IsKeyDown(.L) {
            mario.anim = .Running
            mario_velocity.x = SPEED
            mario.facing = .Right
        } else {
            mario.anim = .Idle
            mario_velocity.x = 0
            mario.curr_frame = 0
        }

        mario.anim_timer += rl.GetFrameTime()
        if mario.anim_timer > mario.frame_len {
            mario.anim_timer = 0
            mario.curr_frame = (mario.curr_frame + 1) % mario.num_frames
        }

        if rl.IsKeyReleased(.M) {
            play_music = !play_music
        }

        mario_velocity.y += GRAVITY * rl.GetFrameTime()

        if mario.is_grounded && (rl.IsKeyPressed(.SPACE) || rl.IsKeyPressed(.K)) {
            mario_velocity.y = JUMP
            mario.is_grounded = false
        }

        if mario.is_grounded {
            mario_velocity.y = 0
        }
        mario.pos += mario_velocity * rl.GetFrameTime()


        bounds_checks(&mario, ground, &brickF, &brickD)
        draw_background(background, tile)
        draw_player(&mario)
        draw_bricks(&brickF, &brickD)

        check_collisions(&mario, &brickF, &brickD)
    }
}
