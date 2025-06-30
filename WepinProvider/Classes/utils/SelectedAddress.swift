//
//  selectedAddress.swift
//  Pods
//
//  Created by iotrust on 6/11/25.
//

import WepinCore

internal func getSelectedAddress(network: String) -> StorageDataType.WepinSelectedAddress? {
    let selectedAddressInfo = WepinCore.shared.storage.getStorage(key: "selectedAddress", type: [StorageDataType.WepinSelectedAddress].self)
    print("selectedAddressInfo: \(selectedAddressInfo)")
    if (selectedAddressInfo == nil || selectedAddressInfo?.count == 0) {
        return nil
    }
    
    guard let userId = WepinCore.shared.storage.getStorage(key: "user_id") as? String else {
        print("Invalid Login Session")
        return nil
    }
    
    let selectedAddress = selectedAddressInfo?.first { info in
        info.network == network && info.userId == userId
    }
    return selectedAddress ?? nil
}

internal func setSelectedAddress(network: String, address: String) {
    // 1. 사용자 ID 확인 (await 추가)
    print("setSelectedAddress")
    guard let userId = WepinCore.shared.storage.getStorage(key: "user_id") as? String else {
        print("Invalid Login Session")
        return
    }
    
    // 2. 기존 배열 조회 (nil이면 빈 배열 사용)
    var selectedAddressInfo = WepinCore.shared.storage.getStorage(
        key: "selectedAddress",
        type: [StorageDataType.WepinSelectedAddress].self
    ) ?? []
    
    // 3. 업데이트 또는 추가
    if let foundIndex = selectedAddressInfo.firstIndex(where: { info in
        info.network == network && info.userId == userId
    }) {
        selectedAddressInfo[foundIndex] = StorageDataType.WepinSelectedAddress(
            userId: userId,
            network: network,
            address: address.lowercased()   //현재 evm, kaia 만 지원하므로. 다른 네트워크(Solana 등) 지원 시 네트워크에 따라 다른 처리 필요
        )
    } else {
        // 새 항목 추가
        selectedAddressInfo.append(StorageDataType.WepinSelectedAddress(
            userId: userId,
            network: network,
            address: address.lowercased()
        ))
    }
    
    // 4. 업데이트된 배열을 다시 저장 (중요!)
    WepinCore.shared.storage.setStorage(
        key: "selectedAddress",
        data: selectedAddressInfo
    )
}
