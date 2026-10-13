<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Product;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class RecycleBinApiController extends Controller
{
    /**
     * Display a listing of soft-deleted products for mobile app.
     */
    public function index(Request $request): JsonResponse
    {
        $search = $request->query('search');
        $perPage = (int) $request->query('per_page', 20);

        $query = Product::onlyTrashed()
            ->when($search, function ($q) use ($search) {
                $q->where(function ($sub) use ($search) {
                    $sub->where('name', 'like', "%{$search}%")
                        ->orWhere('sku', 'like', "%{$search}%")
                        ->orWhere('description', 'like', "%{$search}%");
                });
            })
            ->latest('deleted_at');

        $trashedProducts = $query->paginate($perPage);

        return response()->json([
            'success' => true,
            'data' => $trashedProducts->items(),
            'meta' => [
                'current_page' => $trashedProducts->currentPage(),
                'last_page' => $trashedProducts->lastPage(),
                'per_page' => $trashedProducts->perPage(),
                'total' => $trashedProducts->total(),
            ],
            'stats' => [
                'total_in_trash' => Product::onlyTrashed()->count(),
                'active_catalog_count' => Product::count(),
            ],
        ], 200);
    }

    /**
     * Restore a soft-deleted product back to active catalog.
     */
    public function restore(int $id): JsonResponse
    {
        $product = Product::onlyTrashed()->find($id);

        if (! $product) {
            return response()->json([
                'success' => false,
                'message' => 'Product not found in Recycle Bin.',
            ], 404);
        }

        $product->restore();

        return response()->json([
            'success' => true,
            'message' => "Product '{$product->name}' restored successfully.",
            'data' => $product,
        ], 200);
    }

    /**
     * Permanently delete a product from database.
     */
    public function forceDelete(int $id): JsonResponse
    {
        $product = Product::onlyTrashed()->find($id);

        if (! $product) {
            return response()->json([
                'success' => false,
                'message' => 'Product not found in Recycle Bin.',
            ], 404);
        }

        $name = $product->name;
        $product->forceDelete();

        return response()->json([
            'success' => true,
            'message' => "Product '{$name}' permanently deleted.",
        ], 200);
    }

    /**
     * Restore all soft-deleted products back to active catalog.
     */
    public function restoreAll(): JsonResponse
    {
        $count = Product::onlyTrashed()->count();
        Product::onlyTrashed()->restore();

        return response()->json([
            'success' => true,
            'message' => "All {$count} products restored successfully.",
            'restored_count' => $count,
        ], 200);
    }

    /**
     * Permanently delete all soft-deleted products from database.
     */
    public function emptyTrash(): JsonResponse
    {
        $count = Product::onlyTrashed()->count();
        Product::onlyTrashed()->forceDelete();

        return response()->json([
            'success' => true,
            'message' => "Recycle bin emptied ({$count} records removed).",
            'deleted_count' => $count,
        ], 200);
    }
}
