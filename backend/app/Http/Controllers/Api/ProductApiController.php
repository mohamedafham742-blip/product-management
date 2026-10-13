<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Product;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class ProductApiController extends Controller
{
    /**
     * Display a paginated listing of products for the Flutter mobile application.
     */
    public function index(Request $request): JsonResponse
    {
        $search = $request->query('search');
        $status = $request->query('status', 'all');
        $perPage = (int) $request->query('per_page', 15);

        $query = Product::query()
            ->when($search, function ($q, $search) {
                $q->where(function ($sub) use ($search) {
                    $sub->where('name', 'like', "%{$search}%")
                        ->orWhere('sku', 'like', "%{$search}%")
                        ->orWhere('description', 'like', "%{$search}%");
                });
            })
            ->when($status && $status !== 'all', function ($q) use ($status) {
                $q->where('status', $status);
            })
            ->latest('id');

        $products = $query->paginate($perPage);

        return response()->json([
            'success' => true,
            'data' => $products->items(),
            'meta' => [
                'current_page' => $products->currentPage(),
                'last_page' => $products->lastPage(),
                'per_page' => $products->perPage(),
                'total' => $products->total(),
            ],
            'stats' => [
                'total_products' => Product::count(),
                'active_products' => Product::where('status', 'active')->count(),
                'inactive_products' => Product::where('status', 'inactive')->count(),
                'total_stock' => (int) Product::sum('quantity'),
            ]
        ], 200);
    }

    /**
     * Store a newly created product via REST API.
     */
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'sku' => ['required', 'string', 'max:100', 'unique:products,sku'],
            'description' => ['nullable', 'string'],
            'price' => ['required', 'numeric', 'min:0'],
            'quantity' => ['required', 'integer', 'min:0'],
            'status' => ['required', 'in:active,inactive'],
        ], [
            'name.required' => 'The product name is required.',
            'sku.required' => 'The product SKU / code is required.',
            'sku.unique' => 'A product with this SKU already exists.',
            'price.required' => 'The product price is required.',
            'price.numeric' => 'Price must be a valid number.',
            'quantity.required' => 'Quantity is required.',
            'status.required' => 'Status is required.',
        ]);

        $product = Product::create($validated);

        return response()->json([
            'success' => true,
            'message' => 'Product created successfully.',
            'data' => $product
        ], 201);
    }

    /**
     * Display details of a specific product.
     */
    public function show(int $id): JsonResponse
    {
        $product = Product::find($id);

        if (! $product) {
            return response()->json([
                'success' => false,
                'message' => 'Product not found.'
            ], 404);
        }

        return response()->json([
            'success' => true,
            'data' => $product
        ], 200);
    }

    /**
     * Update the specified product via REST API.
     */
    public function update(Request $request, int $id): JsonResponse
    {
        $product = Product::find($id);

        if (! $product) {
            return response()->json([
                'success' => false,
                'message' => 'Product not found.'
            ], 404);
        }

        $validated = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'sku' => ['required', 'string', 'max:100', Rule::unique('products', 'sku')->ignore($product->id)],
            'description' => ['nullable', 'string'],
            'price' => ['required', 'numeric', 'min:0'],
            'quantity' => ['required', 'integer', 'min:0'],
            'status' => ['required', 'in:active,inactive'],
        ], [
            'name.required' => 'The product name is required.',
            'sku.required' => 'The product SKU is required.',
            'sku.unique' => 'A product with this SKU already exists.',
            'price.required' => 'The product price is required.',
            'price.numeric' => 'Price must be a valid number.',
            'quantity.required' => 'Quantity is required.',
            'status.required' => 'Status is required.',
        ]);

        $product->update($validated);

        return response()->json([
            'success' => true,
            'message' => 'Product updated successfully.',
            'data' => $product
        ], 200);
    }

    /**
     * Remove the specified product (Soft Delete) via REST API.
     */
    public function destroy(int $id): JsonResponse
    {
        $product = Product::find($id);

        if (! $product) {
            return response()->json([
                'success' => false,
                'message' => 'Product not found.'
            ], 404);
        }

        $product->delete();

        return response()->json([
            'success' => true,
            'message' => "Product '{$product->name}' moved to Recycle Bin."
        ], 200);
    }
}
