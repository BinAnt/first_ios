import Foundation

enum BookingRoute: Hashable {
    case departments(Hospital)
    case doctors(Hospital, Department)
    case schedule(Hospital, Department, Doctor)
    case confirm(Hospital, Department, Doctor, TimeSlot)
    case success(Appointment)
}
