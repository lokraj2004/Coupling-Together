package com.example.coupling_together;

import android.content.Context;
import android.hardware.usb.*;
import android.os.Build;

import java.util.*;

// Manually define these missing constants:

public class USBHelper {
    private static final int USB_REQUEST_GET_DESCRIPTOR = 0x06;
    private static final int USB_DT_STRING = 0x03;
    private static String getStringDescriptor(UsbDeviceConnection connection, int index) {
        byte[] buffer = new byte[255];
        int len = connection.controlTransfer(UsbConstants.USB_DIR_IN | UsbConstants.USB_TYPE_STANDARD,
                USB_REQUEST_GET_DESCRIPTOR,
                (USB_DT_STRING << 8) | index,
                0,
                buffer,
                buffer.length,
                2000);
        if (len < 0) return null;
        try {
            return new String(buffer, 2, len - 2, "UTF-16LE");
        } catch (Exception e) {
            return null;
        }
    }
    public static Map<String, Object> getUSBDeviceInfo(Context context) {
        UsbManager usbManager = (UsbManager) context.getSystemService(Context.USB_SERVICE);
        HashMap<String, UsbDevice> deviceList = usbManager.getDeviceList();

        if (deviceList.isEmpty()) return null;

        UsbDevice device = deviceList.values().iterator().next(); // First device

        Map<String, Object> info = new HashMap<>();
        info.put("Device Name", device.getDeviceName());
        info.put("Vendor ID", device.getVendorId());
        info.put("Product ID", device.getProductId());
        info.put("Device Class", device.getDeviceClass());
        info.put("Device Subclass", device.getDeviceSubclass());
        info.put("Protocol", device.getDeviceProtocol());
        info.put("USB Version", device.getVersion());
        if (device.getConfigurationCount() > 0) {
            info.put("Max Power (mA)", device.getConfiguration(0).getMaxPower());
        }
        info.put("Number of Configurations", device.getConfigurationCount());
        info.put("Number of Interfaces", device.getInterfaceCount());

        UsbDeviceConnection connection = usbManager.openDevice(device);
        if (connection != null) {
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                    info.put("Serial Number", connection.getSerial());
                    info.put("Product Name", device.getProductName());
                    info.put("Manufacturer Name", device.getManufacturerName());
                }
            } catch (Exception e) {
                info.put("Descriptor Error", e.getMessage());
            }
        }

        for (int i = 0; i < device.getInterfaceCount(); i++) {
            UsbInterface iface = device.getInterface(i);
            Map<String, Object> ifaceMap = new HashMap<>();
            ifaceMap.put("ID", iface.getId());
            ifaceMap.put("Class", iface.getInterfaceClass());
            ifaceMap.put("Subclass", iface.getInterfaceSubclass());
            ifaceMap.put("Protocol", iface.getInterfaceProtocol());

            for (int j = 0; j < iface.getEndpointCount(); j++) {
                UsbEndpoint ep = iface.getEndpoint(j);
                Map<String, Object> epMap = new HashMap<>();
                epMap.put("Address", ep.getAddress());
                epMap.put("Attributes", ep.getAttributes());
                epMap.put("Direction", ep.getDirection());
                epMap.put("Type", ep.getType());
                ifaceMap.put("Endpoint " + j, epMap);
            }

            info.put("Interface " + i, ifaceMap);
        }

        return info;
    }


}
