package com.gamestudio100.studio_amazon;

import android.content.Context;
import android.os.Handler;
import android.os.Looper;

import androidx.annotation.NonNull;

import com.amazon.device.iap.PurchasingListener;
import com.amazon.device.iap.PurchasingService;
import com.amazon.device.iap.model.FulfillmentResult;
import com.amazon.device.iap.model.Product;
import com.amazon.device.iap.model.ProductDataResponse;
import com.amazon.device.iap.model.PurchaseResponse;
import com.amazon.device.iap.model.PurchaseUpdatesResponse;
import com.amazon.device.iap.model.Receipt;
import com.amazon.device.iap.model.UserDataResponse;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

/**
 * Amazon Appstore SDK (3.x) IAP köprüsü. Kanal sözleşmesi studio_core
 * NativeChannelPurchaseService ile aynıdır (init/buy/restore/finish ->
 * "purchase" olayları). Fire OS dışı cihazlarda (Appstore istemcisi yok)
 * init "available=false" döner.
 */
public class StudioAmazonPlugin implements FlutterPlugin, MethodChannel.MethodCallHandler, PurchasingListener {
    private static final String CHANNEL = "studio_amazon/iap";

    private MethodChannel channel;
    private Context context;
    private final Handler main = new Handler(Looper.getMainLooper());
    private boolean registered = false;
    private MethodChannel.Result pendingInit;
    private Set<String> consumables = new HashSet<>();
    private boolean restoring = false;

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        context = binding.getApplicationContext();
        channel = new MethodChannel(binding.getBinaryMessenger(), CHANNEL);
        channel.setMethodCallHandler(this);
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
        channel = null;
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        try {
            switch (call.method) {
                case "init": {
                    List<String> skus = call.argument("skus");
                    List<String> cons = call.argument("consumables");
                    consumables = cons == null ? new HashSet<>() : new HashSet<>(cons);
                    if (!registered) {
                        PurchasingService.registerListener(context, this);
                        registered = true;
                    }
                    if (pendingInit != null) pendingInit.success(unavailable());
                    pendingInit = result;
                    PurchasingService.getUserData();
                    PurchasingService.getProductData(new HashSet<>(skus == null ? new ArrayList<String>() : skus));
                    // Appstore istemcisi yanıt vermezse (Fire OS dışı) bekleme sınırı.
                    main.postDelayed(() -> {
                        if (pendingInit == result) {
                            pendingInit = null;
                            result.success(unavailable());
                        }
                    }, 15000);
                    break;
                }
                case "buy": {
                    String sku = call.argument("sku");
                    PurchasingService.purchase(sku);
                    result.success(true);
                    break;
                }
                case "restore": {
                    restoring = true;
                    PurchasingService.getPurchaseUpdates(true);
                    result.success(null);
                    break;
                }
                case "finish": {
                    String id = call.argument("id");
                    PurchasingService.notifyFulfillment(id, FulfillmentResult.FULFILLED);
                    result.success(null);
                    break;
                }
                default:
                    result.notImplemented();
            }
        } catch (Throwable t) {
            result.error("amazon_iap", String.valueOf(t.getMessage()), null);
        }
    }

    private static Map<String, Object> unavailable() {
        Map<String, Object> m = new HashMap<>();
        m.put("available", false);
        m.put("products", new ArrayList<Object>());
        return m;
    }

    private void emit(String sku, String id, String status, boolean verified) {
        final Map<String, Object> m = new HashMap<>();
        m.put("sku", sku == null ? "" : sku);
        m.put("id", id == null ? "" : id);
        m.put("status", status);
        m.put("verified", verified);
        main.post(() -> {
            if (channel != null) channel.invokeMethod("purchase", m);
        });
    }

    @Override
    public void onUserDataResponse(UserDataResponse response) {
        // Kullanıcı kimliği tutulmaz; yalnızca istemcinin yanıt verdiği görülür.
    }

    @Override
    public void onProductDataResponse(ProductDataResponse response) {
        final MethodChannel.Result r = pendingInit;
        pendingInit = null;
        if (r == null) return;
        final Map<String, Object> out = new HashMap<>();
        List<Object> products = new ArrayList<>();
        boolean ok = response.getRequestStatus() == ProductDataResponse.RequestStatus.SUCCESSFUL;
        if (ok && response.getProductData() != null) {
            for (Product p : response.getProductData().values()) {
                Map<String, Object> pm = new HashMap<>();
                pm.put("id", p.getSku());
                pm.put("price", p.getPrice() == null ? "" : p.getPrice());
                products.add(pm);
            }
        }
        out.put("available", ok && !products.isEmpty());
        out.put("products", products);
        main.post(() -> r.success(out));
        // Açılışta teslim edilmemiş (bildirilmemiş) satın almalar.
        if (ok) PurchasingService.getPurchaseUpdates(false);
    }

    @Override
    public void onPurchaseResponse(PurchaseResponse response) {
        Receipt receipt = response.getReceipt();
        switch (response.getRequestStatus()) {
            case SUCCESSFUL:
                if (receipt != null && !receipt.isCanceled()) {
                    emit(receipt.getSku(), receipt.getReceiptId(), "purchased", true);
                }
                break;
            case ALREADY_PURCHASED:
                restoring = true;
                PurchasingService.getPurchaseUpdates(true);
                break;
            case INVALID_SKU:
            case NOT_SUPPORTED:
            case FAILED:
            default:
                emit(receipt == null ? "" : receipt.getSku(), "", "canceled", false);
        }
    }

    @Override
    public void onPurchaseUpdatesResponse(PurchaseUpdatesResponse response) {
        if (response.getRequestStatus() != PurchaseUpdatesResponse.RequestStatus.SUCCESSFUL) {
            restoring = false;
            return;
        }
        for (Receipt receipt : response.getReceipts()) {
            if (receipt == null || receipt.isCanceled()) continue;
            boolean consumable = consumables.contains(receipt.getSku());
            // Tüketilebilirler yalnızca henüz bildirilmemişse burada görünür:
            // teslim et. Tüketilemezler "geri yükle" ile yeniden etkinleşir.
            emit(receipt.getSku(), receipt.getReceiptId(), consumable ? "purchased" : "restored", true);
        }
        if (response.hasMore()) {
            PurchasingService.getPurchaseUpdates(false);
        } else {
            restoring = false;
        }
    }
}
