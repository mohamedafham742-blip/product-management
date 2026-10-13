<script>
    import { router } from '@inertiajs/svelte';

    let {
        user = {},
        metrics = {
            total_products: 0,
            active_products: 0,
            inactive_products: 0,
            total_stock: 0,
            low_stock_count: 0,
            out_of_stock_count: 0,
            trash_count: 0
        },
        recentProducts = []
    } = $props();

    let loggingOut = $state(false);

    function handleLogout() {
        loggingOut = true;
        router.post('/logout', {}, {
            onFinish: () => {
                loggingOut = false;
            }
        });
    }

    function formatPrice(val) {
        const num = parseFloat(val);
        return isNaN(num) ? 'Rs. 0.00' : `Rs. ${num.toFixed(2)}`;
    }

    // Real-time auto-sync: automatically update dashboard metrics & recent products when changes happen on mobile
    $effect(() => {
        const interval = setInterval(() => {
            router.reload({
                only: ['metrics', 'recentProducts'],
                preserveScroll: true,
                preserveState: true,
            });
        }, 2000);

        return () => {
            clearInterval(interval);
        };
    });
</script>

<svelte:head>
    <title>Dashboard | Product Management System</title>
</svelte:head>

<div class="min-h-screen bg-[#FAF7F4] text-[#2E2825] flex flex-col selection:bg-[#3D3835] selection:text-white relative">
    
    <!-- Top Navigation Bar (Assemble Clean Aesthetic) -->
    <header class="border-b border-[#E7DCD2] bg-white/90 backdrop-blur-md sticky top-0 z-30">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-16 flex items-center justify-between">
            
            <!-- Brand Logo & Navigation Links -->
            <div class="flex items-center gap-8">
                <a href="/dashboard" class="flex items-center gap-3">
                    <div class="w-9 h-9 rounded-xl bg-[#3D3835] flex items-center justify-center text-white shadow-sm">
                        <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4" />
                        </svg>
                    </div>
                    <div>
                        <div class="font-semibold text-sm tracking-wide text-[#2B2623] uppercase">
                            Product System
                        </div>
                    </div>
                </a>

                <!-- Nav Menu Links -->
                <nav class="hidden md:flex items-center gap-1">
                    <a
                        href="/dashboard"
                        class="px-3.5 py-1.5 rounded-lg text-xs font-semibold text-[#2B2623] bg-[#EFE7E1] border border-[#DCCEC4] transition"
                    >
                        Dashboard
                    </a>
                    <a
                        href="/products"
                        class="px-3.5 py-1.5 rounded-lg text-xs font-medium text-[#7D716A] hover:text-[#2B2623] hover:bg-[#F4ECE7] transition"
                    >
                        Products
                    </a>
                    <a
                        href="/recycle-bin"
                        class="px-3.5 py-1.5 rounded-lg text-xs font-medium text-[#7D716A] hover:text-[#2B2623] hover:bg-[#F4ECE7] transition flex items-center gap-1.5"
                    >
                        <span>Recycle Bin</span>
                        {#if metrics.trash_count > 0}
                            <span class="px-1.5 py-0.2 rounded-full text-[10px] bg-[#A33B2E] text-white font-mono">
                                {metrics.trash_count}
                            </span>
                        {/if}
                    </a>
                </nav>
            </div>

            <!-- User Info & Logout -->
            <div class="flex items-center gap-4">
                <div class="hidden sm:flex items-center gap-2 px-3 py-1.5 rounded-xl bg-[#F5ECE5] border border-[#E5D7CD] text-xs text-[#5C5049]">
                    <span class="w-2 h-2 rounded-full bg-[#3D8A52]"></span>
                    <span class="font-medium text-[#2B2623]">{user.name || 'Admin User'}</span>
                    <span class="text-[#8C7F77]">({user.email || 'admin@example.com'})</span>
                </div>

                <button
                    type="button"
                    onclick={handleLogout}
                    disabled={loggingOut}
                    class="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-xs font-semibold text-[#8F3528] bg-[#FAF0EE] hover:bg-[#F5E2DE] border border-[#EBCAC4] transition-all cursor-pointer disabled:opacity-50"
                >
                    <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1" />
                    </svg>
                    <span>{loggingOut ? 'Signing out...' : 'Sign Out'}</span>
                </button>
            </div>
        </div>
    </header>

    <!-- Main Content Area -->
    <main class="flex-1 max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8 w-full">
        
        <!-- Welcome Hero Banner (Assemble Warm Style) -->
        <div class="relative overflow-hidden rounded-2xl bg-gradient-to-r from-[#E6D4CA] via-[#F2EAE4] to-[#FAF7F4] border border-[#E0D1C6] p-7 sm:p-9 mb-8 shadow-sm">
            <div class="relative z-10 flex flex-col md:flex-row md:items-center md:justify-between gap-6">
                <div>
                    <h1 class="text-2xl sm:text-3xl font-light tracking-wide text-[#2B2623]">
                        Welcome back, <span class="font-semibold">{user.name || 'Admin'}</span>
                    </h1>
                    <p class="mt-2 text-xs sm:text-sm text-[#6E615A] max-w-2xl leading-relaxed">
                        Overview of your product catalog, inventory stock levels, and quick management actions.
                    </p>
                </div>

                <!-- Action Shortcuts -->
                <div class="flex flex-wrap items-center gap-3">
                    <a
                        href="/products"
                        class="inline-flex items-center gap-2 px-4 py-2.5 rounded-xl text-xs font-semibold text-white bg-[#3D3835] hover:bg-[#2B2623] transition shadow-xs"
                    >
                        <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M12 4v16m8-8H4" />
                        </svg>
                        <span>Manage Products</span>
                    </a>

                    <a
                        href="/recycle-bin"
                        class="inline-flex items-center gap-2 px-4 py-2.5 rounded-xl text-xs font-semibold text-[#5C5049] bg-white hover:bg-[#F2ECE6] border border-[#E0D2C7] transition shadow-xs"
                    >
                        <svg class="w-4 h-4 text-[#A33B2E]" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                        </svg>
                        <span>Recycle Bin ({metrics.trash_count})</span>
                    </a>
                </div>
            </div>
        </div>

        <!-- 4-Card Product Metrics Grid -->
        <div class="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
            
            <!-- Card 1: Total Products -->
            <div class="bg-white border border-[#E5D8CF] rounded-2xl p-5 shadow-sm hover:border-[#D4C3B7] transition">
                <div class="flex items-center justify-between">
                    <span class="text-[11px] font-semibold text-[#8A7C73] uppercase tracking-wider">Total Products</span>
                    <div class="w-7 h-7 rounded-lg bg-[#FAF5F0] border border-[#EAE0D8] text-[#3D3835] flex items-center justify-center">
                        <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4" />
                        </svg>
                    </div>
                </div>
                <div class="text-3xl font-semibold text-[#2B2623] mt-2">{metrics.total_products}</div>
                <div class="text-[11px] text-[#8A7C73] mt-1">Active in store catalog</div>
            </div>

            <!-- Card 2: Active Products -->
            <div class="bg-white border border-[#E5D8CF] rounded-2xl p-5 shadow-sm hover:border-[#D4C3B7] transition">
                <div class="flex items-center justify-between">
                    <span class="text-[11px] font-semibold text-[#2C6E3D] uppercase tracking-wider flex items-center gap-1.5">
                        <span class="w-2 h-2 rounded-full bg-[#2C6E3D]"></span> Active Items
                    </span>
                    <div class="w-7 h-7 rounded-lg bg-[#EAF5ED] border border-[#CDE5D4] text-[#2C6E3D] flex items-center justify-center">
                        <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M5 13l4 4L19 7" />
                        </svg>
                    </div>
                </div>
                <div class="text-3xl font-semibold text-[#2B2623] mt-2">{metrics.active_products}</div>
                <div class="text-[11px] text-[#8A7C73] mt-1">Visible &amp; published</div>
            </div>

            <!-- Card 3: Inactive Items -->
            <div class="bg-white border border-[#E5D8CF] rounded-2xl p-5 shadow-sm hover:border-[#D4C3B7] transition">
                <div class="flex items-center justify-between">
                    <span class="text-[11px] font-semibold text-[#A66D24] uppercase tracking-wider flex items-center gap-1.5">
                        <span class="w-2 h-2 rounded-full bg-[#C2822B]"></span> Inactive Items
                    </span>
                    <div class="w-7 h-7 rounded-lg bg-[#FFF8EB] border border-[#F3DEB8] text-[#A66D24] flex items-center justify-center">
                        <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M18.364 18.364A9 9 0 005.636 5.636m12.728 12.728A9 9 0 015.636 5.636m12.728 12.728L5.636 5.636" />
                        </svg>
                    </div>
                </div>
                <div class="text-3xl font-semibold text-[#2B2623] mt-2">{metrics.inactive_products}</div>
                <div class="text-[11px] text-[#8A7C73] mt-1">Hidden from public</div>
            </div>

            <!-- Card 4: Recycle Bin -->
            <div class="bg-white border border-[#E5D8CF] rounded-2xl p-5 shadow-sm hover:border-[#D4C3B7] transition">
                <div class="flex items-center justify-between">
                    <span class="text-[11px] font-semibold text-[#A33B2E] uppercase tracking-wider flex items-center gap-1.5">
                        <span class="w-2 h-2 rounded-full bg-[#A33B2E]"></span> Recycle Bin
                    </span>
                    <div class="w-7 h-7 rounded-lg bg-[#FAF0EE] border border-[#EBCAC4] text-[#A33B2E] flex items-center justify-center">
                        <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                        </svg>
                    </div>
                </div>
                <div class="text-3xl font-semibold text-[#2B2623] mt-2">{metrics.trash_count}</div>
                <div class="text-[11px] text-[#8A7C73] mt-1">
                    <a href="/recycle-bin" class="text-[#A33B2E] hover:underline font-medium">View trashed items &rarr;</a>
                </div>
            </div>

        </div>

        <!-- Inventory Layout: Recent Products & Inventory Health -->
        <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
            
            <!-- Left: Recent Products Table (2 Cols) -->
            <div class="lg:col-span-2 bg-white border border-[#E5D8CF] rounded-2xl overflow-hidden shadow-sm">
                <div class="p-5 border-b border-[#EAE0D7] flex items-center justify-between bg-[#FAF6F2]">
                    <div>
                        <h2 class="text-sm font-semibold text-[#2B2623] uppercase tracking-wider">
                            Recently Added Products
                        </h2>
                        <p class="text-xs text-[#8A7C73] mt-0.5">
                            Latest inventory records created in database
                        </p>
                    </div>
                    <a
                        href="/products"
                        class="text-xs font-semibold text-[#3D3835] hover:text-[#111] hover:underline"
                    >
                        View All Products &rarr;
                    </a>
                </div>

                <div class="overflow-x-auto">
                    <table class="w-full text-left border-collapse">
                        <thead>
                            <tr class="border-b border-[#EAE0D7] text-[11px] uppercase tracking-wider font-semibold text-[#7D7068] bg-[#FAF7F4]">
                                <th class="py-3 px-5">Product &amp; SKU</th>
                                <th class="py-3 px-5">Price</th>
                                <th class="py-3 px-5">Stock</th>
                                <th class="py-3 px-5">Status</th>
                            </tr>
                        </thead>
                        <tbody class="divide-y divide-[#F2EAE3] text-xs">
                            {#if recentProducts.length === 0}
                                <tr>
                                    <td colspan="4" class="py-10 text-center text-[#8A7C73]">
                                        No products in the database yet.
                                    </td>
                                </tr>
                            {:else}
                                {#each recentProducts as p}
                                    <tr class="hover:bg-[#FAF6F2] transition">
                                        <td class="py-3.5 px-5">
                                            <div class="font-medium text-[#2B2623]">{p.name}</div>
                                            <div class="font-mono text-[10px] text-[#8C7F78]">{p.sku}</div>
                                        </td>
                                        <td class="py-3.5 px-5 font-mono font-medium text-[#2B2623]">
                                            {formatPrice(p.price)}
                                        </td>
                                        <td class="py-3.5 px-5">
                                            <span class="font-medium {p.quantity < 10 ? 'text-[#9E6517]' : 'text-[#2B2623]'}">
                                                {p.quantity} units
                                            </span>
                                        </td>
                                        <td class="py-3.5 px-5">
                                            {#if p.status === 'active'}
                                                <span class="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] font-medium bg-[#EAF5ED] text-[#2C6E3D] border border-[#CDE5D4]">
                                                    <span class="w-1 h-1 rounded-full bg-[#2C6E3D]"></span> Active
                                                </span>
                                            {:else}
                                                <span class="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] font-medium bg-[#F5ECE6] text-[#7D7068] border border-[#E0D2C7]">
                                                    <span class="w-1 h-1 rounded-full bg-[#8C7D75]"></span> Inactive
                                                </span>
                                            {/if}
                                        </td>
                                    </tr>
                                {/each}
                            {/if}
                        </tbody>
                    </table>
                </div>
            </div>

            <!-- Right: Stock Health & Quick Summary (1 Col) -->
            <div class="space-y-6">
                
                <!-- Stock Health Card -->
                <div class="bg-white border border-[#E5D8CF] rounded-2xl p-6 shadow-sm">
                    <div class="flex items-center gap-3 mb-4">
                        <div class="w-9 h-9 rounded-xl bg-[#F4ECE6] border border-[#E5D6CC] text-[#3D3835] flex items-center justify-center">
                            <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                                <path stroke-linecap="round" stroke-linejoin="round" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
                            </svg>
                        </div>
                        <div>
                            <h3 class="text-xs font-semibold uppercase tracking-wider text-[#2B2623]">Warehouse Stock</h3>
                            <p class="text-[11px] text-[#8A7C73]">Inventory availability summary</p>
                        </div>
                    </div>

                    <div class="space-y-3 text-xs">
                        <div class="flex items-center justify-between py-2 border-b border-[#F0E6DE]">
                            <span class="text-[#8A7C73]">Total Units in Stock</span>
                            <span class="font-semibold text-[#2B2623] text-sm">{metrics.total_stock}</span>
                        </div>

                        <div class="flex items-center justify-between py-2 border-b border-[#F0E6DE]">
                            <span class="text-[#8A7C73] flex items-center gap-1.5">
                                <span class="w-2 h-2 rounded-full bg-[#E5832B]"></span> Low Stock Items (&lt; 10)
                            </span>
                            <span class="font-semibold {metrics.low_stock_count > 0 ? 'text-[#C2822B]' : 'text-[#2B2623]'}">
                                {metrics.low_stock_count}
                            </span>
                        </div>

                        <div class="flex items-center justify-between py-2">
                            <span class="text-[#8A7C73] flex items-center gap-1.5">
                                <span class="w-2 h-2 rounded-full bg-[#A33B2E]"></span> Out of Stock Items (0)
                            </span>
                            <span class="font-semibold {metrics.out_of_stock_count > 0 ? 'text-[#A33B2E]' : 'text-[#2B2623]'}">
                                {metrics.out_of_stock_count}
                            </span>
                        </div>
                    </div>
                </div>

                <!-- Fast Actions Panel -->
                <div class="bg-gradient-to-br from-[#FAF5F0] to-[#F2EAE4] border border-[#E0D2C7] rounded-2xl p-6 shadow-sm">
                    <h3 class="text-xs font-semibold uppercase tracking-wider text-[#2B2623] mb-1">
                        Quick Shortcuts
                    </h3>
                    <p class="text-[11px] text-[#8A7C73] mb-4">
                        Navigate to key management areas
                    </p>

                    <div class="space-y-2">
                        <a
                            href="/products"
                            class="w-full flex items-center justify-between p-3 rounded-xl bg-white/90 hover:bg-white border border-[#E5D8CF] text-xs font-semibold text-[#2B2623] transition"
                        >
                            <span>Open Product Catalog</span>
                            <span>&rarr;</span>
                        </a>

                        <a
                            href="/recycle-bin"
                            class="w-full flex items-center justify-between p-3 rounded-xl bg-white/90 hover:bg-white border border-[#E5D8CF] text-xs font-semibold text-[#2B2623] transition"
                        >
                            <span>Open Recycle Bin</span>
                            <span class="text-xs px-2 py-0.5 rounded-full bg-[#FAF0EE] text-[#A33B2E]">
                                {metrics.trash_count}
                            </span>
                        </a>
                    </div>
                </div>

            </div>

        </div>

    </main>

    <!-- Footer -->
    <footer class="border-t border-[#E7DCD2] py-4 mt-auto bg-white/60">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 flex flex-col sm:flex-row items-center justify-between text-xs text-[#8A7C73] gap-2">
            <div>
                Product Management System
            </div>
            <div>
                Laravel &bull; Svelte 5 &bull; MySQL
            </div>
        </div>
    </footer>
</div>
