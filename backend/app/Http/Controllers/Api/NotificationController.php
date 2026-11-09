<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\NotificationResource;
use App\Models\Notification;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class NotificationController extends Controller
{
    /**
     * GET /api/notifications
     * Daftar notifikasi milik pengguna yang login (urut terbaru, pagination).
     */
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        $perPage = max(1, min(50, (int) $request->input('per_page', 15)));
        $page = max(1, (int) $request->input('page', 1));

        $paginated = Notification::with('game')
            ->where('user_id', $user->id)
            ->orderBy('created_at', 'desc')
            ->orderBy('id', 'desc')
            ->paginate($perPage, ['*'], 'page', $page);

        return response()->json([
            'success' => true,
            'message' => 'Daftar notifikasi berhasil diambil',
            'data'    => [
                'notifications' => NotificationResource::collection($paginated->items()),
                'pagination'    => [
                    'current_page' => $paginated->currentPage(),
                    'last_page'    => $paginated->lastPage(),
                    'per_page'     => $paginated->perPage(),
                    'total'        => $paginated->total(),
                ],
            ],
        ], 200);
    }

    /**
     * GET /api/notifications/unread-count
     * Jumlah notifikasi yang belum dibaca milik pengguna yang login.
     */
    public function unreadCount(Request $request): JsonResponse
    {
        $user = $request->user();
        $count = Notification::where('user_id', $user->id)
            ->whereNull('dibaca_pada')
            ->count();

        return response()->json([
            'success' => true,
            'message' => 'Jumlah notifikasi belum dibaca berhasil diambil',
            'data'    => [
                'unread_count' => $count,
            ],
        ], 200);
    }

    /**
     * PUT /api/notifications/{id}/read
     * Tandai satu notifikasi sebagai sudah dibaca (isi dibaca_pada).
     */
    public function markAsRead(Request $request, $id): JsonResponse
    {
        $notification = Notification::with('game')->find($id);

        if (! $notification) {
            return response()->json([
                'success' => false,
                'message' => 'Notifikasi tidak ditemukan.',
            ], 404);
        }

        if ($notification->user_id !== $request->user()->id) {
            return response()->json([
                'success' => false,
                'message' => 'Anda tidak memiliki izin untuk mengakses notifikasi ini.',
            ], 403);
        }

        if ($notification->dibaca_pada === null) {
            $notification->dibaca_pada = now();
            $notification->save();
        }

        return response()->json([
            'success' => true,
            'message' => 'Notifikasi berhasil ditandai sebagai dibaca',
            'data'    => new NotificationResource($notification),
        ], 200);
    }

    /**
     * PUT /api/notifications/read-all
     * Tandai semua notifikasi milik pengguna yang login sebagai sudah dibaca.
     */
    public function markAllAsRead(Request $request): JsonResponse
    {
        $user = $request->user();

        $updated = Notification::where('user_id', $user->id)
            ->whereNull('dibaca_pada')
            ->update(['dibaca_pada' => now()]);

        return response()->json([
            'success' => true,
            'message' => 'Semua notifikasi berhasil ditandai sebagai dibaca',
            'data'    => [
                'updated_count' => $updated,
            ],
        ], 200);
    }
}
