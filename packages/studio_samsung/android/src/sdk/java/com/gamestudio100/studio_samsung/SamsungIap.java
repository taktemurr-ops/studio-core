package com.gamestudio100.studio_samsung;

import android.content.Context;
import android.os.Handler;
import android.os.Looper;

import androidx.annotation.NonNull;

import com.samsung.android.sdk.iap.lib.helper.HelperDefine;
import com.samsung.android.sdk.iap.lib.helper.IapHelper;
import com.samsung.android.sdk.iap.lib.vo.OwnedProductVo;
import com.samsung.android.sdk.iap.lib.vo.ProductVo;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

/**
 * Samsung IAP SDK 6.x (IapHelper) köprüsü. Kanal sözleşmesi studio_core
 * NativeChannelPurchaseService ile aynıdır. Yalnızca SDK AAR'ı sağlandığında
 * derlenir (bkz. android/build.gradle).
 */
class SamsungIap implements MethodChannel.MethodCallHandler {
    private final Context context;
    private final MethodChannel channel;
    private final Handler main = new Handler(Looper.getMainLooper());
    private Set<String> consumables = new HashSet<>();
    private IapHelper helper;

    SamsungIap(Context context, MethodChannel channel) {
        this.context = context;
        this.channel = channel;
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        try {
            switch (call.method) {
                case "init":
                    init(call, result);
                    break;
                case "buy":
                    buy(call.argument("sku"), result);
                    break;
                case "restore":
                    owned();
                    result.success(null);
                    break;
                case "finish":
                    finish(call, result);
                    break;
                default:
                    result.notImplemented();
            }
        } catch (Throwable t) {
            result.error("samsung_iap", String.valueOf(t.getMessage()), null);
        }
    }

    private void init(MethodCall call, MethodChannel.Result result) {
        List<String> skus = call.argument("skus");
        List<String> cons = call.argument("consumables");
        Boolean test = call.argument("test");
        consumables = cons == null ? new HashSet<>() : new HashSet<>(cons);
        helper = IapHelper.getInstance(context);
        helper.setOperationMode(Boolean.TRUE.equals(test)
                ? HelperDefine.OperationMode.OPERATION_MODE_TEST
                : HelperDefine.OperationMode.OPERATION_MODE_PRODUCTION);
        String ids = skus == null ? "" : String.join(",", skus);
        helper.getProductsDetails(ids, (error, list) -> {
            Map<String, Object> out = new HashMap<>();
            List<Object> products = new ArrayList<>();
            boolean ok = error != null && error.getErrorCode() == IapHelper.IAP_ERROR_NONE;
            if (ok && list != null) {
                for (ProductVo p : list) {
                    Map<String, Object> pm = new HashMap<>();
                    pm.put("id", p.getItemId());
                    pm.put("price", p.getItemPriceString());
                    products.add(pm);
                }
            }
            out.put("available", ok && !products.isEmpty());
            out.put("products", products);
            out.put("sdk", true);
            main.post(() -> result.success(out));
            // Ödenmiş ama tüketilmemiş (teslimi yarım kalmış) ürünler.
            if (ok) owned();
        });
    }

    private void buy(String sku, MethodChannel.Result result) {
        if (helper == null || sku == null) {
            result.success(false);
            return;
        }
        helper.startPayment(sku, null, (error, purchase) -> {
            if (error != null && error.getErrorCode() == IapHelper.IAP_ERROR_NONE && purchase != null) {
                emit(purchase.getItemId(), purchase.getPurchaseId(), "purchased", true);
            } else if (error != null && error.getErrorCode() == IapHelper.IAP_ERROR_ALREADY_PURCHASED) {
                owned();
            } else if (error != null && error.getErrorCode() == IapHelper.IAP_PAYMENT_IS_CANCELED) {
                emit(sku, "", "canceled", false);
            } else {
                emit(sku, "", "error", false);
            }
        });
        result.success(true);
    }

    /** Sahip olunanlar: tüketilemezler geri yüklenir, tüketilebilirler teslim edilir. */
    private void owned() {
        if (helper == null) return;
        helper.getOwnedList(IapHelper.PRODUCT_TYPE_ALL, (error, list) -> {
            if (error == null || error.getErrorCode() != IapHelper.IAP_ERROR_NONE || list == null) return;
            for (OwnedProductVo o : list) {
                boolean consumable = consumables.contains(o.getItemId());
                emit(o.getItemId(), o.getPurchaseId(), consumable ? "purchased" : "restored", true);
            }
        });
    }

    private void finish(MethodCall call, MethodChannel.Result result) {
        Boolean consumable = call.argument("consumable");
        String id = call.argument("id");
        if (helper != null && Boolean.TRUE.equals(consumable) && id != null && !id.isEmpty()) {
            helper.consumePurchasedItems(id, (error, list) -> { });
        }
        result.success(null);
    }

    private void emit(String sku, String id, String status, boolean verified) {
        final Map<String, Object> m = new HashMap<>();
        m.put("sku", sku == null ? "" : sku);
        m.put("id", id == null ? "" : id);
        m.put("status", status);
        m.put("verified", verified);
        main.post(() -> channel.invokeMethod("purchase", m));
    }
}
