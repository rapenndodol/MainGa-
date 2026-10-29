<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

class AuthTest extends TestCase
{
    use RefreshDatabase;

    /**
     * Test: Registrasi berhasil dengan data valid.
     */
    public function test_user_can_register_with_valid_data(): void
    {
        $payload = [
            'nama' => 'Dimas Gamer',
            'email' => 'dimas@example.com',
            'password' => 'password123',
        ];

        $response = $this->postJson('/api/register', $payload);

        $response->assertStatus(201)
            ->assertJson([
                'success' => true,
                'message' => 'Registrasi berhasil',
                'data' => [
                    'user' => [
                        'nama' => 'Dimas Gamer',
                        'email' => 'dimas@example.com',
                    ],
                ],
            ]);

        $this->assertNotEmpty($response->json('data.token'));
        $this->assertDatabaseHas('users', [
            'email' => 'dimas@example.com',
            'nama' => 'Dimas Gamer',
        ]);

        $user = User::where('email', 'dimas@example.com')->first();
        $this->assertTrue(Hash::check('password123', $user->password));
    }

    /**
     * Test: Registrasi gagal bila email sudah terdaftar.
     */
    public function test_register_fails_when_email_already_registered(): void
    {
        User::factory()->create([
            'nama' => 'User Lama',
            'email' => 'existing@example.com',
        ]);

        $payload = [
            'nama' => 'User Baru',
            'email' => 'existing@example.com',
            'password' => 'password123',
        ];

        $response = $this->postJson('/api/register', $payload);

        $response->assertStatus(422)
            ->assertJsonStructure([
                'success',
                'message',
                'errors' => ['email'],
            ]);
    }

    /**
     * Test: Registrasi gagal bila password kurang dari 8 karakter.
     */
    public function test_register_fails_when_password_too_short(): void
    {
        $payload = [
            'nama' => 'Short Pass',
            'email' => 'short@example.com',
            'password' => '1234567', // 7 chars
        ];

        $response = $this->postJson('/api/register', $payload);

        $response->assertStatus(422)
            ->assertJsonStructure([
                'success',
                'message',
                'errors' => ['password'],
            ]);
    }

    /**
     * Test: Login berhasil dengan kredensial benar.
     */
    public function test_user_can_login_with_correct_credentials(): void
    {
        $user = User::create([
            'nama' => 'Dimas Test',
            'email' => 'dimas.login@example.com',
            'password' => Hash::make('secret123'),
        ]);

        $payload = [
            'email' => 'dimas.login@example.com',
            'password' => 'secret123',
        ];

        $response = $this->postJson('/api/login', $payload);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Login berhasil',
                'data' => [
                    'user' => [
                        'id' => $user->id,
                        'email' => 'dimas.login@example.com',
                    ],
                ],
            ]);

        $this->assertNotEmpty($response->json('data.token'));
    }

    /**
     * Test: Login gagal dengan password salah (status 401).
     */
    public function test_user_cannot_login_with_wrong_password(): void
    {
        User::create([
            'nama' => 'Dimas Test',
            'email' => 'dimas.wrong@example.com',
            'password' => Hash::make('secret123'),
        ]);

        $payload = [
            'email' => 'dimas.wrong@example.com',
            'password' => 'passwordsalah',
        ];

        $response = $this->postJson('/api/login', $payload);

        $response->assertStatus(401)
            ->assertJson([
                'success' => false,
                'message' => 'Email atau password salah.',
            ]);
    }

    /**
     * Test: Login gagal jika email tidak ditemukan (status 401).
     */
    public function test_user_cannot_login_with_nonexistent_email(): void
    {
        $payload = [
            'email' => 'unknown@example.com',
            'password' => 'secret123',
        ];

        $response = $this->postJson('/api/login', $payload);

        $response->assertStatus(401)
            ->assertJson([
                'success' => false,
                'message' => 'Email atau password salah.',
            ]);
    }

    /**
     * Test: Logout berhasil dan token dicabut.
     */
    public function test_user_can_logout_with_valid_token(): void
    {
        $user = User::create([
            'nama' => 'Dimas Logout',
            'email' => 'dimas.logout@example.com',
            'password' => Hash::make('secret123'),
        ]);

        $token = $user->createToken('auth_token')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer '.$token)
            ->postJson('/api/logout');

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'message' => 'Logout berhasil',
            ]);

        // Token sudah dihapus
        $this->assertCount(0, $user->fresh()->tokens);
    }

    /**
     * Test: Akses ke endpoint terproteksi tanpa token menghasilkan status 401.
     */
    public function test_unauthenticated_access_without_token_returns_401(): void
    {
        $responseLogout = $this->postJson('/api/logout');
        $responseLogout->assertStatus(401)
            ->assertJson([
                'success' => false,
            ]);

        $responseMe = $this->getJson('/api/me');
        $responseMe->assertStatus(401)
            ->assertJson([
                'success' => false,
            ]);
    }
}
