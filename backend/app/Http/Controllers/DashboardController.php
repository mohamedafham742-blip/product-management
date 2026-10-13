<?php

namespace App\Http\Controllers;

use App\Models\Product;
use Illuminate\Http\Request;
use Inertia\Inertia;
use Inertia\Response;

class DashboardController extends Controller
{
    /**
     * Display the Product Management dashboard with live analytics and recent inventory.
     */
    public function index(Request $request): Response
    {
        $metrics = [
            'total_products' => Product::count(),
            'active_products' => Product::where('status', 'active')->count(),
            'inactive_products' => Product::where('status', 'inactive')->count(),
            'total_stock' => (int) Product::sum('quantity'),
            'low_stock_count' => Product::where('quantity', '<', 10)->where('quantity', '>', 0)->count(),
            'out_of_stock_count' => Product::where('quantity', '<=', 0)->count(),
            'trash_count' => Product::onlyTrashed()->count(),
        ];

        $recentProducts = Product::latest('id')
            ->take(5)
            ->get(['id', 'name', 'sku', 'price', 'quantity', 'status', 'created_at'])
            ->map(function ($product) {
                return [
                    'id' => $product->id,
                    'name' => $product->name,
                    'sku' => $product->sku,
                    'price' => $product->price,
                    'quantity' => $product->quantity,
                    'status' => $product->status,
                    'created_at' => $product->created_at?->format('M d, Y'),
                ];
            });

        return Inertia::render('Dashboard', [
            'user' => [
                'id' => $request->user()->id,
                'name' => $request->user()->name,
                'email' => $request->user()->email,
            ],
            'metrics' => $metrics,
            'recentProducts' => $recentProducts,
        ]);
    }
}
