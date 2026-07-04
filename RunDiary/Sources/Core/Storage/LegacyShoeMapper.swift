//
//  LegacyShoeMapper.swift
//  RunDiary
//
//  Created by 김혜지 on 5/6/26.
//

// SwiftData에 저장된 옛 ShoeStorage 슬러그(`"nike-alphafly-3"`)를
// 사람이 읽을 수 있는 이름으로 디코드한다.
// 신규 ShoeCache lookup이 실패한 경우의 fallback.
enum LegacyShoeMapper {
    private static let knownLegacyNames: [String: String] = [
        "nike-alphafly-3": "Nike Alphafly 3",
        "nike-vaporfly-4": "Nike Vaporfly 4",
        "adidas-adizero-adios-pro-4": "Adidas Adizero Adios Pro 4",
        "adidas-adizero-evo-sl": "Adidas Adizero Evo SL",
        "asics-novablast-5": "Asics Novablast 5",
        "asics-metaspeed-sky-tokyo": "Asics Metaspeed Sky Tokyo",
        "new-balance-fuelcell-supercomp-trainer-v2": "New Balance FuelCell SuperComp Trainer v2",
        "hoka-mach-6": "Hoka Mach 6",
        "hoka-rocket-x-3": "Hoka Rocket X 3",
        "brooks-hyperion-max-3": "Brooks Hyperion Max 3",
        "saucony-endorphin-elite-2": "Saucony Endorphin Elite 2",
        "saucony-endorphin-speed-5": "Saucony Endorphin Speed 5",
        "puma-fast-r-nitro-elite-3": "Puma Fast-R Nitro Elite 3",
        "on-cloudboom-echo-3": "On Cloudboom Echo 3",
        "mizuno-neo-zen": "Mizuno Neo Zen",
    ]

    static func decodeName(from legacyId: String) -> String? {
        guard !legacyId.isEmpty else { return nil }

        if let known = knownLegacyNames[legacyId] { return known }

        return legacyId.split(separator: "-")
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .joined(separator: " ")
    }
}
