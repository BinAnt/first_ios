import Foundation

enum PatientValidator {
    static func nameError(_ name: String) -> String? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return "请填写就诊人姓名"
        }
        if trimmed.count < 2 {
            return "姓名至少 2 个字"
        }
        if trimmed.count > 20 {
            return "姓名不超过 20 个字"
        }
        return nil
    }

    static func phoneError(_ phone: String) -> String? {
        if phone.isEmpty {
            return "请填写手机号"
        }
        let pattern = "^1[3-9]\\d{9}$"
        if phone.range(of: pattern, options: .regularExpression) == nil {
            return "请输入 11 位有效手机号"
        }
        return nil
    }
}
