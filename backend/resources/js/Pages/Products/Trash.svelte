<script>
    import { router } from '@inertiajs/svelte';

    let {
        trashedProducts = { data: [], links: [] },
        filters = { search: '' },
        stats = { total_in_trash: 0, active_catalog_count: 0 }
    } = $props();

    let search = $state('');
    let searchTimeout = null;

    $effect(() => {
        search = filters.search || '';
    });

    // Real-time auto-sync: automatically update trash list when changes happen from mobile app
    $effect(() => {
        const interval = setInterval(() => {
            if (!showForceDeleteModal && !showEmptyBinModal && !actionInProgress && (!search || search.trim() === '')) {
                router.reload({
                    only: ['trashedProducts', 'stats'],
                    preserveScroll: true,
                    preserveState: true,
                });
            }
        }, 2500);

        return () => {
            clearInterval(interval);
        };
    });

    function applySearch() {
        router.get('/recycle-bin', {
            search: search || undefined,
        }, {
            preserveState: true,
            replace: true,
        });
    }

    function handleSearchInput() {
        clearTimeout(searchTimeout);
        searchTimeout = setTimeout(() => {
            applySearch();
        }, 300);
    }

    // Modal & Action states
    let showForceDeleteModal = $state(false);
    let showEmptyBinModal = $state(false);
    let selectedProduct = $state(null);
    let actionInProgress = $state(false);

    function restoreSingle(id) {
        actionInProgress = true;
        router.post(`/recycle-bin/${id}/restore`, {}, {
            preserveScroll: true,
            onFinish: () => {
                actionInProgress = false;
            }
        });
    }

    function openForceDeleteModal(product) {
        selectedProduct = product;
        showForceDeleteModal = true;
    }

    function cancelForceDelete() {
        if (actionInProgress) return;
        showForceDeleteModal = false;
        selectedProduct = null;
    }

    function cancelEmptyBin() {
        if (actionInProgress) return;
        showEmptyBinModal = false;
    }

    function confirmForceDelete() {
        if (!selectedProduct || actionInProgress) return;
        actionInProgress = true;
        router.delete(`/recycle-bin/${selectedProduct.id}/force-delete`, {
            preserveScroll: true,
            preserveState: true,
            onFinish: () => {
                actionInProgress = false;
                showForceDeleteModal = false;
                selectedProduct = null;
            }
        });
    }

    function restoreAll() {
        if (!confirm('Are you sure you want to restore all items back to the active catalog?')) return;
        actionInProgress = true;
        router.post('/recycle-bin/restore-all', {}, {
            preserveScroll: true,
            onFinish: () => {
                actionInProgress = false;
            }
        });
    }

    function confirmEmptyBin() {
        actionInProgress = true;
        router.delete('/recycle-bin/empty', {
            preserveScroll: true,
            onFinish: () => {
                actionInProgress = false;
                showEmptyBinModal = false;
            }
        });
    }

    function handleLogout() {
        router.post('/logout');
    }

    function formatPrice(val) {
        const num = parseFloat(val);
        return isNaN(num) ? 'Rs. 0.00' : `Rs. ${num.toFixed(2)}`;
    }
</script>

<svelte:head>
    <title>Recycle Bin | Product Management System</title>
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
                        class="px-3.5 py-1.5 rounded-lg text-xs font-medium text-[#7D716A] hover:text-[#2B2623] hover:bg-[#F4ECE7] transition"
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
                        class="px-3.5 py-1.5 rounded-lg text-xs font-semibold text-[#2B2623] bg-[#EFE7E1] border border-[#DCCEC4] transition flex items-center gap-1.5"
                    >
                        <span>Recycle Bin</span>
                        {#if stats.total_in_trash > 0}
                            <span class="px-1.5 py-0.2 rounded-full text-[10px] bg-[#A33B2E] text-white font-mono">
                                {stats.total_in_trash}
                            </span>
                        {/if}
                    </a>
                </nav>
            </div>

            <!-- Actions & Logout -->
            <div class="flex items-center gap-3">
                <button
                    type="button"
                    onclick={handleLogout}
                    class="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-xs font-semibold text-[#8F3528] bg-[#FAF0EE] hover:bg-[#F5E2DE] border border-[#EBCAC4] transition-all cursor-pointer"
                >
                    <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1" />
                    </svg>
                    <span>Sign Out</span>
                </button>
            </div>
        </div>
    </header>

    <!-- Main Content Area -->
    <main class="flex-1 max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8 w-full">
        
        <!-- Summary Cards -->
        <div class="grid grid-cols-1 sm:grid-cols-2 gap-4 mb-8">
            <div class="bg-white border border-[#E5D8CF] rounded-2xl p-5 shadow-sm flex items-center justify-between">
                <div>
                    <div class="text-[11px] font-semibold text-[#A33B2E] uppercase tracking-wider flex items-center gap-1.5">
                        <span class="w-2 h-2 rounded-full bg-[#A33B2E]"></span> Deleted Products in Bin
                    </div>
                    <div class="text-3xl font-semibold text-[#2B2623] mt-1">{stats.total_in_trash}</div>
                    <div class="text-[11px] text-[#8A7C73] mt-0.5">Can be restored or permanently removed</div>
                </div>
                <div class="w-12 h-12 rounded-2xl bg-[#FAF0EE] border border-[#EBCAC4] text-[#A33B2E] flex items-center justify-center">
                    <svg class="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.75">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                    </svg>
                </div>
            </div>

            <div class="bg-white border border-[#E5D8CF] rounded-2xl p-5 shadow-sm flex items-center justify-between">
                <div>
                    <div class="text-[11px] font-semibold text-[#2C6E3D] uppercase tracking-wider flex items-center gap-1.5">
                        <span class="w-2 h-2 rounded-full bg-[#2C6E3D]"></span> Active Product Catalog
                    </div>
                    <div class="text-3xl font-semibold text-[#2B2623] mt-1">{stats.active_catalog_count}</div>
                    <div class="text-[11px] text-[#8A7C73] mt-0.5">Live products available on store</div>
                </div>
                <div class="w-12 h-12 rounded-2xl bg-[#EAF5ED] border border-[#CDE5D4] text-[#2C6E3D] flex items-center justify-center">
                    <svg class="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.75">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4" />
                    </svg>
                </div>
            </div>
        </div>

        <!-- Section Header & Quick Actions -->
        <div class="flex flex-col md:flex-row md:items-center md:justify-between gap-4 mb-6">
            <div>
                <h1 class="text-2xl sm:text-3xl font-light tracking-wide text-[#2B2623] flex items-center gap-3">
                    <span>Recycle Bin</span>
                    <span class="text-xs px-2.5 py-0.5 rounded-full bg-[#FAF0EE] text-[#A33B2E] border border-[#EBCAC4] font-semibold">
                        {stats.total_in_trash} Soft-deleted
                    </span>
                </h1>
                <p class="mt-1 text-xs text-[#8A7C73]">
                    Safely recover deleted items or permanently purge them from the database
                </p>
            </div>

            <!-- Global Actions -->
            {#if stats.total_in_trash > 0}
                <div class="flex items-center gap-2.5">
                    <button
                        type="button"
                        onclick={restoreAll}
                        disabled={actionInProgress}
                        class="inline-flex items-center gap-1.5 px-3.5 py-2 rounded-xl text-xs font-semibold text-[#2B2623] bg-white hover:bg-[#F4ECE7] border border-[#DCCEC4] transition shadow-xs cursor-pointer disabled:opacity-50"
                    >
                        <svg class="w-3.5 h-3.5 text-[#2C6E3D]" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
                        </svg>
                        <span>Restore All Items</span>
                    </button>

                    <button
                        type="button"
                        onclick={() => showEmptyBinModal = true}
                        disabled={actionInProgress}
                        class="inline-flex items-center gap-1.5 px-3.5 py-2 rounded-xl text-xs font-semibold text-white bg-[#A33B2E] hover:bg-[#852C21] transition shadow-xs cursor-pointer disabled:opacity-50"
                    >
                        <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                        </svg>
                        <span>Empty Recycle Bin</span>
                    </button>
                </div>
            {/if}
        </div>

        <!-- Search Bar -->
        <div class="bg-white border border-[#E5D8CF] rounded-2xl p-4 mb-6 shadow-sm flex items-center justify-between">
            <div class="relative w-full sm:w-80">
                <div class="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none text-[#9E9087]">
                    <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                    </svg>
                </div>
                <input
                    type="text"
                    placeholder="Search soft-deleted products..."
                    bind:value={search}
                    oninput={handleSearchInput}
                    class="block w-full pl-10 pr-4 py-2 bg-[#FAF7F4] border border-[#E5D8CF] focus:border-[#3D3835] focus:ring-2 focus:ring-[#3D3835]/15 rounded-xl text-[#2B2623] placeholder-[#A89C94] text-xs transition focus:outline-none"
                />
            </div>

            <a
                href="/products"
                class="hidden sm:inline-flex items-center gap-1.5 text-xs font-semibold text-[#5C5049] hover:text-[#2B2623] px-3 py-1.5 rounded-xl hover:bg-[#F2ECE6] transition"
            >
                <span>&larr; Back to Active Products</span>
            </a>
        </div>

        <!-- Trashed Products Table -->
        <div class="bg-white border border-[#E5D8CF] rounded-2xl overflow-hidden shadow-sm">
            <div class="overflow-x-auto">
                <table class="w-full text-left border-collapse">
                    <thead>
                        <tr class="border-b border-[#EAE0D7] bg-[#FAF6F2] text-[11px] uppercase tracking-wider font-semibold text-[#7D7068]">
                            <th class="py-3.5 px-5">Deleted Product &amp; SKU</th>
                            <th class="py-3.5 px-5">Price</th>
                            <th class="py-3.5 px-5">Deleted Date &amp; Time</th>
                            <th class="py-3.5 px-5 text-right">Actions</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-[#F2EAE3] text-xs">
                        {#if trashedProducts.data.length === 0}
                            <tr>
                                <td colspan="4" class="py-16 text-center text-[#8A7C73]">
                                    <div class="w-12 h-12 rounded-2xl bg-[#F5ECE5] text-[#8C7D75] mx-auto mb-3 flex items-center justify-center">
                                        <svg class="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M5 13l4 4L19 7" />
                                        </svg>
                                    </div>
                                    <div class="font-medium text-[#2B2623] text-sm">Recycle Bin is empty</div>
                                    <p class="text-xs text-[#8A7C73] mt-1 max-w-sm mx-auto">
                                        {search ? `No trashed products matching "${search}"` : 'No deleted items. All products are active in the catalog.'}
                                    </p>
                                    <a
                                        href="/products"
                                        class="mt-4 inline-flex items-center gap-1.5 px-4 py-2 rounded-xl text-xs font-semibold text-white bg-[#3D3835] hover:bg-[#2B2623] transition"
                                    >
                                        <span>View Product Catalog</span>
                                    </a>
                                </td>
                            </tr>
                        {:else}
                            {#each trashedProducts.data as item}
                                <tr class="hover:bg-[#FAF6F2] transition">
                                    <td class="py-4 px-5">
                                        <div class="flex items-center gap-3">
                                            <div class="w-9 h-9 rounded-xl bg-[#FAF0EE] border border-[#EBCAC4] text-[#A33B2E] flex items-center justify-center flex-shrink-0">
                                                <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.75">
                                                    <path stroke-linecap="round" stroke-linejoin="round" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                                                </svg>
                                            </div>
                                            <div>
                                                <div class="font-medium text-[#2B2623] text-xs flex items-center gap-2">
                                                    <span>{item.name}</span>
                                                    <span class="font-mono text-[10px] px-1.5 py-0.5 rounded bg-[#ECE3DC] text-[#5C5049] border border-[#DCCEC2]">
                                                        {item.sku}
                                                    </span>
                                                </div>
                                                <p class="text-[11px] text-[#8C7F78] line-clamp-1 max-w-xs mt-0.5">
                                                    {item.description || 'No description provided'}
                                                </p>
                                            </div>
                                        </div>
                                    </td>
                                    <td class="py-4 px-5 font-mono text-xs font-semibold text-[#2B2623]">
                                        {formatPrice(item.price)}
                                    </td>
                                    <td class="py-4 px-5 text-xs text-[#8A7C73]">
                                        {item.deleted_at}
                                    </td>
                                    <td class="py-4 px-5 text-right">
                                        <div class="flex items-center justify-end gap-2">
                                            <!-- Restore Button -->
                                            <button
                                                type="button"
                                                title="Restore Product"
                                                onclick={() => restoreSingle(item.id)}
                                                disabled={actionInProgress}
                                                class="inline-flex items-center gap-1 px-2.5 py-1.5 rounded-lg text-xs font-semibold text-[#2C6E3D] bg-[#EAF5ED] hover:bg-[#DDF0E2] border border-[#CDE5D4] transition cursor-pointer disabled:opacity-50"
                                            >
                                                <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                                                    <path stroke-linecap="round" stroke-linejoin="round" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
                                                </svg>
                                                <span>Restore</span>
                                            </button>

                                            <!-- Force Delete Button -->
                                            <button
                                                type="button"
                                                title="Permanent Delete"
                                                onclick={() => openForceDeleteModal(item)}
                                                disabled={actionInProgress}
                                                class="inline-flex items-center gap-1 px-2.5 py-1.5 rounded-lg text-xs font-semibold text-[#A33B2E] bg-[#FAF0EE] hover:bg-[#F7DFDB] border border-[#EBCAC4] transition cursor-pointer disabled:opacity-50"
                                            >
                                                <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                                                    <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
                                                </svg>
                                                <span>Delete Forever</span>
                                            </button>
                                        </div>
                                    </td>
                                </tr>
                            {/each}
                        {/if}
                    </tbody>
                </table>
            </div>

            <!-- Pagination Links -->
            {#if trashedProducts.links && trashedProducts.links.length > 3}
                <div class="py-3.5 px-5 border-t border-[#EAE0D7] bg-[#FAF6F2] flex flex-col sm:flex-row items-center justify-between gap-3">
                    <div class="text-xs text-[#8A7C73]">
                        Showing {trashedProducts.data.length} records
                    </div>
                    <div class="flex items-center gap-1.5">
                        {#each trashedProducts.links as link}
                            {#if link.url}
                                <a
                                    href={link.url}
                                    class="px-3 py-1.5 rounded-lg text-xs font-medium transition {link.active ? 'bg-[#3D3835] text-white' : 'bg-white text-[#5C5049] hover:bg-[#F2ECE6] border border-[#E5D8CF]'}"
                                >
                                    {@html link.label}
                                </a>
                            {:else}
                                <span class="px-3 py-1.5 rounded-lg text-xs font-medium text-[#B5A79E] bg-[#FAF6F2]">
                                    {@html link.label}
                                </span>
                            {/if}
                        {/each}
                    </div>
                </div>
            {/if}
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

<!-- ================= MODALS ================= -->

<!-- 1. PERMANENT FORCE DELETE MODAL -->
{#if showForceDeleteModal && selectedProduct}
    <div
        class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/40 backdrop-blur-xs"
        onclick={(e) => { if (e.target === e.currentTarget && !actionInProgress) cancelForceDelete(); }}
        onkeydown={(e) => { if (e.key === 'Escape' && !actionInProgress) cancelForceDelete(); }}
        tabindex="-1"
        role="dialog"
        aria-modal="true"
    >
        <div class="bg-white border border-[#E5D8CF] rounded-2xl max-w-md w-full p-6 shadow-xl animate-in fade-in zoom-in-95 duration-150">
            <div class="flex items-start justify-between pb-3 mb-3 border-b border-[#F0E6DE]">
                <div class="flex items-center gap-3.5">
                    <div class="w-10 h-10 rounded-xl bg-[#FAF0EE] border border-[#EBCAC4] text-[#A33B2E] flex items-center justify-center flex-shrink-0">
                        <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
                        </svg>
                    </div>
                    <div>
                        <h3 class="font-semibold text-sm text-[#2B2623]">Permanently Delete</h3>
                        <p class="text-[11px] text-[#A33B2E] font-medium">This action cannot be undone!</p>
                    </div>
                </div>
                <button
                    type="button"
                    disabled={actionInProgress}
                    onclick={cancelForceDelete}
                    aria-label="Close"
                    class="p-1.5 rounded-lg text-[#8A7C73] hover:text-[#2B2623] hover:bg-[#F2ECE6] transition cursor-pointer disabled:opacity-40"
                >
                    <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
                    </svg>
                </button>
            </div>

            <p class="text-xs text-[#5C5049] leading-relaxed mb-4">
                Are you sure you want to permanently delete <strong class="text-[#2B2623] font-semibold">{selectedProduct.name}</strong> ({selectedProduct.sku})?
                This record will be completely removed from the MySQL database.
            </p>

            <div class="flex items-center justify-end gap-2.5 pt-4 border-t border-[#F0E6DE]">
                <button
                    type="button"
                    disabled={actionInProgress}
                    onclick={cancelForceDelete}
                    class="px-4 py-2 rounded-xl text-xs font-semibold text-[#6E6159] hover:bg-[#F2ECE6] border border-[#E5D8CF] transition cursor-pointer disabled:opacity-50"
                >
                    Cancel (Keep in Bin)
                </button>
                <button
                    type="button"
                    onclick={confirmForceDelete}
                    disabled={actionInProgress}
                    class="px-4 py-2.5 rounded-xl text-xs font-semibold text-white bg-[#A33B2E] hover:bg-[#852C21] transition cursor-pointer disabled:opacity-50 flex items-center gap-2"
                >
                    {#if actionInProgress}
                        <svg class="w-3.5 h-3.5 animate-spin" viewBox="0 0 24 24" fill="none">
                            <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                            <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                        </svg>
                        <span>Deleting Forever...</span>
                    {:else}
                        <span>Yes, Delete Forever</span>
                    {/if}
                </button>
            </div>
        </div>
    </div>
{/if}

<!-- 2. EMPTY ENTIRE RECYCLE BIN MODAL -->
{#if showEmptyBinModal}
    <div
        class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/40 backdrop-blur-xs"
        onclick={(e) => { if (e.target === e.currentTarget && !actionInProgress) cancelEmptyBin(); }}
        onkeydown={(e) => { if (e.key === 'Escape' && !actionInProgress) cancelEmptyBin(); }}
        tabindex="-1"
        role="dialog"
        aria-modal="true"
    >
        <div class="bg-white border border-[#E5D8CF] rounded-2xl max-w-md w-full p-6 shadow-xl animate-in fade-in zoom-in-95 duration-150">
            <div class="flex items-start justify-between pb-3 mb-3 border-b border-[#F0E6DE]">
                <div class="flex items-center gap-3.5">
                    <div class="w-10 h-10 rounded-xl bg-[#FAF0EE] border border-[#EBCAC4] text-[#A33B2E] flex items-center justify-center flex-shrink-0">
                        <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                        </svg>
                    </div>
                    <div>
                        <h3 class="font-semibold text-sm text-[#2B2623]">Empty Recycle Bin</h3>
                        <p class="text-[11px] text-[#A33B2E] font-medium">Permanent removal of {stats.total_in_trash} items</p>
                    </div>
                </div>
                <button
                    type="button"
                    disabled={actionInProgress}
                    onclick={cancelEmptyBin}
                    aria-label="Close"
                    class="p-1.5 rounded-lg text-[#8A7C73] hover:text-[#2B2623] hover:bg-[#F2ECE6] transition cursor-pointer disabled:opacity-40"
                >
                    <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
                    </svg>
                </button>
            </div>

            <p class="text-xs text-[#5C5049] leading-relaxed mb-4">
                Are you sure you want to permanently erase all <strong class="text-[#2B2623] font-semibold">{stats.total_in_trash} items</strong> from the Recycle Bin?
                They will be irrevocably deleted from the MySQL database.
            </p>

            <div class="flex items-center justify-end gap-2.5 pt-4 border-t border-[#F0E6DE]">
                <button
                    type="button"
                    disabled={actionInProgress}
                    onclick={cancelEmptyBin}
                    class="px-4 py-2 rounded-xl text-xs font-semibold text-[#6E6159] hover:bg-[#F2ECE6] border border-[#E5D8CF] transition cursor-pointer disabled:opacity-50"
                >
                    Cancel (Keep Bin)
                </button>
                <button
                    type="button"
                    onclick={confirmEmptyBin}
                    disabled={actionInProgress}
                    class="px-4 py-2.5 rounded-xl text-xs font-semibold text-white bg-[#A33B2E] hover:bg-[#852C21] transition cursor-pointer disabled:opacity-50 flex items-center gap-2"
                >
                    {#if actionInProgress}
                        <svg class="w-3.5 h-3.5 animate-spin" viewBox="0 0 24 24" fill="none">
                            <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                            <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                        </svg>
                        <span>Emptying...</span>
                    {:else}
                        <span>Empty Everything</span>
                    {/if}
                </button>
            </div>
        </div>
    </div>
{/if}
