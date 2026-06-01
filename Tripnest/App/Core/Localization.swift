import SwiftUI

/// Langues prises en charge par l'application.
enum AppLanguage: String, CaseIterable {
    case fr, en, vi

    var label: String {
        switch self {
        case .fr: return "Français"
        case .en: return "English"
        case .vi: return "Tiếng Việt"
        }
    }

    var flag: String {
        switch self {
        case .fr: return "🇫🇷"
        case .en: return "🇬🇧"
        case .vi: return "🇻🇳"
        }
    }

    /// Locale système associée (formats de date, nombres…).
    var locale: Locale {
        switch self {
        case .fr: return Locale(identifier: "fr_FR")
        case .en: return Locale(identifier: "en_US")
        case .vi: return Locale(identifier: "vi_VN")
        }
    }
}

/// Source de vérité pour la langue choisie. Le changement est appliqué en direct
/// dans toute l'app (RootView se reconstruit via `.id(localizer.language)`).
final class Localizer: ObservableObject {
    static let shared = Localizer()

    @Published var language: AppLanguage {
        didSet { UserDefaults.standard.set(language.rawValue, forKey: Self.key) }
    }

    private static let key = "tripnest.language"

    private init() {
        let raw = UserDefaults.standard.string(forKey: Self.key) ?? AppLanguage.fr.rawValue
        language = AppLanguage(rawValue: raw) ?? .fr
    }
}

/// Traduit un texte français source vers la langue courante.
/// Le français est la clé : pas de table nécessaire, on renvoie le texte tel quel.
/// Pour EN/VI, on cherche dans `TripnestTranslations`. Si absent, on retombe sur le français.
func L(_ fr: String) -> String {
    let lang = Localizer.shared.language
    if lang == .fr { return fr }
    return TripnestTranslations.table[lang]?[fr] ?? fr
}

/// Variante avec interpolation façon `printf` (ex. `L("%d jour", count)`).
func L(_ fr: String, _ args: CVarArg...) -> String {
    String(format: L(fr), arguments: args)
}

/// Tables de traduction EN / VI, indexées par le texte français source.
/// Remplies progressivement, écran par écran.
enum TripnestTranslations {
    static let table: [AppLanguage: [String: String]] = [
        .en: en,
        .vi: vi,
    ]

    // MARK: English
    static let en: [String: String] = [
        // Navigation / TabBar
        "Accueil": "Home",
        "Voyages": "Trips",
        "Budget": "Budget",
        "Profil": "Profile",
        "Spots": "Spots",

        // Profil
        "Mon profil": "My profile",
        "Modifier le profil": "Edit profile",
        "PRÉFÉRENCES": "PREFERENCES",
        "COMPTE": "ACCOUNT",
        "Devise par défaut": "Default currency",
        "Ajouter un ami": "Add a friend",
        "Nom de l'ami": "Friend's name",
        "MES AMIS": "MY FRIENDS",
        "Supprimer": "Delete",
        "Envoyer l'invitation": "Send invitation",
        "SUGGESTIONS": "SUGGESTIONS",
        "En attente": "Pending",
        "Invitation acceptée": "Invitation accepted",
        "%@ a accepté ton invitation.": "%@ accepted your invitation.",
        "Aucun utilisateur ne porte ce nom.": "No user found with this name.",
        "Cet ami est déjà dans ta liste.": "This friend is already in your list.",
        "Notifications": "Notifications",
        "Langue": "Language",
        "Français": "English",
        "Documents · passeport, ID": "Documents · passport, ID",
        "Aide & support": "Help & support",
        "Se déconnecter": "Sign out",
        "Nom affiché": "Display name",
        "Ex. Lucas Martin": "E.g. Lucas Martin",
        "Enregistrer": "Save",
        "Fermer": "Close",
        "Mes documents": "My documents",
        "Stocke ici tes documents de voyage importants.": "Store your important travel documents here.",
        "Passeport": "Passport",
        "Carte d'identité": "ID card",
        "Visa / autorisation": "Visa / permit",
        "Assurance voyage": "Travel insurance",
        "Ajouter": "Add",
        "Pour toute question ou problème, contacte-nous à :": "For any question or issue, contact us at:",
        "Photo de profil": "Profile photo",
        "Prendre une photo": "Take a photo",
        "Choisir dans la galerie": "Choose from gallery",
        "Supprimer la photo": "Remove photo",
        "Annuler": "Cancel",
        "amis": "friends",
        "spots": "spots",
        "voyage(s)": "trip(s)",
        "dépense(s)": "expense(s)",
        "Changer la photo de profil": "Change profile photo",
        "Ajouté · touche pour remplacer": "Added · tap to replace",
        "Partager": "Share",
    ]

    // MARK: Tiếng Việt
    static let vi: [String: String] = [
        // Navigation / TabBar
        "Accueil": "Trang chủ",
        "Voyages": "Chuyến đi",
        "Budget": "Ngân sách",
        "Profil": "Hồ sơ",
        "Spots": "Địa điểm",

        // Profil
        "Mon profil": "Hồ sơ của tôi",
        "Modifier le profil": "Chỉnh sửa hồ sơ",
        "PRÉFÉRENCES": "TÙY CHỌN",
        "COMPTE": "TÀI KHOẢN",
        "Devise par défaut": "Tiền tệ mặc định",
        "Ajouter un ami": "Thêm bạn bè",
        "Nom de l'ami": "Tên bạn bè",
        "MES AMIS": "BẠN BÈ CỦA TÔI",
        "Supprimer": "Xóa",
        "Envoyer l'invitation": "Gửi lời mời",
        "SUGGESTIONS": "GỢI Ý",
        "En attente": "Đang chờ",
        "Invitation acceptée": "Đã chấp nhận lời mời",
        "%@ a accepté ton invitation.": "%@ đã chấp nhận lời mời của bạn.",
        "Aucun utilisateur ne porte ce nom.": "Không tìm thấy người dùng tên này.",
        "Cet ami est déjà dans ta liste.": "Người này đã có trong danh sách của bạn.",
        "Notifications": "Thông báo",
        "Langue": "Ngôn ngữ",
        "Français": "Tiếng Việt",
        "Documents · passeport, ID": "Giấy tờ · hộ chiếu, CMND",
        "Aide & support": "Trợ giúp & hỗ trợ",
        "Se déconnecter": "Đăng xuất",
        "Nom affiché": "Tên hiển thị",
        "Ex. Lucas Martin": "Ví dụ: Lucas Martin",
        "Enregistrer": "Lưu",
        "Fermer": "Đóng",
        "Mes documents": "Giấy tờ của tôi",
        "Stocke ici tes documents de voyage importants.": "Lưu các giấy tờ du lịch quan trọng tại đây.",
        "Passeport": "Hộ chiếu",
        "Carte d'identité": "Căn cước công dân",
        "Visa / autorisation": "Visa / giấy phép",
        "Assurance voyage": "Bảo hiểm du lịch",
        "Ajouter": "Thêm",
        "Pour toute question ou problème, contacte-nous à :": "Mọi câu hỏi hoặc vấn đề, hãy liên hệ:",
        "Photo de profil": "Ảnh hồ sơ",
        "Prendre une photo": "Chụp ảnh",
        "Choisir dans la galerie": "Chọn từ thư viện",
        "Supprimer la photo": "Xóa ảnh",
        "Annuler": "Hủy",
        "amis": "bạn bè",
        "spots": "địa điểm",
        "voyage(s)": "chuyến đi",
        "dépense(s)": "chi tiêu",
        "Changer la photo de profil": "Đổi ảnh hồ sơ",
        "Ajouté · touche pour remplacer": "Đã thêm · chạm để thay",
        "Partager": "Chia sẻ",
    ]
}
