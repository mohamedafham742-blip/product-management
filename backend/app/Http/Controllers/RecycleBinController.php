<?php

namespace App\Http\Controllers;

use App\Models\Product;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Inertia\Inertia;
use Inertia\Response;

class RecycleBinController extends Controller
{
    /**
     * Display a listing of soft-deleted products.
     */
    public function index(Request $request): Response
    {
        $search = $request->query('search');

        $trashedProducts = Product::onlyTrashed()
            ->when($search, function ($query, $search) {
                $query->where(function ($q) use ($search) {
                    $q->where('name', 'like', "%{$search}%")
                      ->orWhere('sku', 'like', "%{$search}%")
                      ->orWhere('description', 'like', "%{$search}%");
                });
            })
            ->latest('deleted_at')
            ->paginate(8)
            ->withQueryString();

        $stats = [
            'total_in_trash' => Product::onlyTrashed()->count(),
            'active_catalog_count' => Product::count(),
        ];

        return Inertia::render('Products/Trash', [
            'trashedProducts' => $trashedProducts,
            'filters' => [
                'search' => $search,
            ],
            'stats' => $stats,
        ]);
    }

    /**
     * Restore a soft-deleted product back to active catalog.
     */
    public function restore(int $id): RedirectResponse
    {
        $product = Product::onlyTrashed()->findOrFail($id);
        $product->restore();

        return redirect()->route('recycle-bin.index')->with('success', "Product '{$product->name}' restored successfully.");
    }

    /**
     * Permanently delete a product from database.
     */
    public function forceDelete(int $id): RedirectResponse
    {
        $product = Product::onlyTrashed()->findOrFail($id);
        $name = $product->name;
        $product->forceDelete();

        return redirect()->route('recycle-bin.index')->with('success', "Product '{$name}' permanently deleted.");
    }

    /**
     * Restore all soft-deleted products back to active catalog.
     */
    public function restoreAll(): RedirectResponse
    {
        $count = Product::onlyTrashed()->count();
        Product::onlyTrashed()->restore();

        return redirect()->route('recycle-bin.index')->with('success', "All {$count} products restored successfully.");
    }

    /**
     * Permanently delete all soft-deleted products from database.
     */
    public function emptyTrash(): RedirectResponse
    {
        $count = Product::onlyTrashed()->count();
        Product::onlyTrashed()->forceDelete();

        return redirect()->route('recycle-bin.index')->with('success', "Recycle bin emptied ({$count} records removed).");
    }
}
