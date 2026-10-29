import Foundation

private struct DepartmentSpec {
    let name: String
    let symbol: String
    let summary: String
    let specialties: [String]
}

private struct HospitalSpec {
    let name: String
    let level: String
    let category: HospitalCategory
    let district: String
    let address: String
    let phone: String
    let openHours: String
    let summary: String
    let symbol: String
    let departments: [DepartmentSpec]
}

private struct CatalogSnapshot {
    var hospitals: [Hospital] = []
    var departments: [Department] = []
    var doctors: [Doctor] = []
}

enum MockCatalog {
    private static let snapshot = makeSnapshot()

    static var hospitals: [Hospital] { snapshot.hospitals }

    static func departments(for hospital: Hospital) -> [Department] {
        snapshot.departments.filter { $0.hospitalID == hospital.id }
    }

    static func doctors(for department: Department) -> [Doctor] {
        snapshot.doctors.filter { $0.departmentID == department.id }
    }

    static func matchingDepartments(hospital: Hospital, query: String) -> [Department] {
        let key = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else { return [] }
        return departments(for: hospital).filter { department in
            department.name.localizedStandardContains(key)
                || department.summary.localizedStandardContains(key)
        }
    }

    static func hasOpenSlot(
        on day: Date,
        hospital: Hospital,
        remaining: (TimeSlot) -> Int
    ) -> Bool {
        for department in departments(for: hospital) {
            for doctor in doctors(for: department) {
                for slot in slots(for: doctor, on: day) where remaining(slot) > 0 {
                    return true
                }
            }
        }
        return false
    }

    static func upcomingDays(count: Int = 7) -> [Date] {
        BookingCalendar.upcomingDays(count: count)
    }

    static func slots(for doctor: Doctor, on day: Date) -> [TimeSlot] {
        let normalizedDay = BookingCalendar.startOfDay(day)
        let datePart = BookingCalendar.datePart(normalizedDay)
        return slotTemplates.enumerated().map { index, template in
            TimeSlot(
                id: StableID.slotID(
                    doctorSerial: doctor.serial,
                    datePart: datePart,
                    slotIndex: index
                ),
                doctorID: doctor.id,
                day: normalizedDay,
                period: template.period,
                timeLabel: template.label,
                initialRemaining: initialRemaining(
                    capacity: template.capacity,
                    doctorSerial: doctor.serial,
                    datePart: datePart,
                    slotIndex: index
                )
            )
        }
    }

    private static func initialRemaining(
        capacity: Int,
        doctorSerial: Int,
        datePart: Int,
        slotIndex: Int
    ) -> Int {
        let score = (doctorSerial * 17 + datePart * 13 + slotIndex * 7) % 11
        switch score {
        case 0:
            return 0
        case 1:
            return 1
        case 2:
            return min(2, capacity)
        default:
            return capacity
        }
    }
}

private struct SlotTemplate {
    let period: DayPeriod
    let label: String
    let capacity: Int
}

private let slotTemplates: [SlotTemplate] = [
    SlotTemplate(period: .morning, label: "08:00-08:30", capacity: 8),
    SlotTemplate(period: .morning, label: "08:30-09:00", capacity: 8),
    SlotTemplate(period: .morning, label: "09:00-09:30", capacity: 6),
    SlotTemplate(period: .morning, label: "09:30-10:00", capacity: 6),
    SlotTemplate(period: .morning, label: "10:00-10:30", capacity: 4),
    SlotTemplate(period: .morning, label: "10:30-11:00", capacity: 4),
    SlotTemplate(period: .afternoon, label: "13:30-14:00", capacity: 6),
    SlotTemplate(period: .afternoon, label: "14:00-14:30", capacity: 6),
    SlotTemplate(period: .afternoon, label: "14:30-15:00", capacity: 5),
    SlotTemplate(period: .afternoon, label: "15:00-15:30", capacity: 5),
    SlotTemplate(period: .afternoon, label: "15:30-16:00", capacity: 4),
    SlotTemplate(period: .afternoon, label: "16:00-16:30", capacity: 3),
]

private let doctorNames = [
    "王建国", "李晓梅", "张伟民", "陈思远", "刘芳", "赵明辉",
    "孙丽娜", "周强", "吴婷婷", "郑浩然", "黄静", "林志强",
    "何敏", "马俊杰", "徐倩", "高峰", "罗斌", "谢雨桐",
    "唐磊", "邓琳", "冯凯", "曹颖", "彭博文", "蒋文静",
    "韩雪", "邱晨", "董强", "魏兰", "苏明", "贾婷",
    "孟浩", "秦雪", "尹杰", "薛梅", "雷阳", "侯亮",
]

private let titlePlans: [(title: String, fee: Int, years: Int, rating: Double)] = [
    ("主任医师", 60, 26, 4.9),
    ("副主任医师", 40, 18, 4.8),
    ("主治医师", 25, 11, 4.7),
]

private func makeSnapshot() -> CatalogSnapshot {
    var snapshot = CatalogSnapshot()
    var doctorSerial = 1
    var nameCursor = 0

    for (hospitalIndex, spec) in hospitalSpecs.enumerated() {
        let hospital = Hospital(
            id: StableID.make(UInt64(hospitalIndex + 1)),
            name: spec.name,
            level: spec.level,
            category: spec.category,
            district: spec.district,
            address: spec.address,
            phone: spec.phone,
            openHours: spec.openHours,
            summary: spec.summary,
            symbol: spec.symbol
        )
        snapshot.hospitals.append(hospital)

        for (departmentIndex, departmentSpec) in spec.departments.enumerated() {
            let department = Department(
                id: StableID.make(UInt64(10_000 + hospitalIndex * 100 + departmentIndex)),
                hospitalID: hospital.id,
                name: departmentSpec.name,
                symbol: departmentSpec.symbol,
                summary: departmentSpec.summary
            )
            snapshot.departments.append(department)

            for doctorIndex in 0..<3 {
                let plan = titlePlans[doctorIndex % titlePlans.count]
                let specialty = departmentSpec.specialties[doctorIndex % departmentSpec.specialties.count]
                let name = doctorNames[nameCursor % doctorNames.count]
                nameCursor += 1
                let doctor = Doctor(
                    id: StableID.make(UInt64(100_000 + doctorSerial)),
                    departmentID: department.id,
                    serial: doctorSerial,
                    name: name,
                    title: plan.title,
                    years: plan.years,
                    rating: plan.rating,
                    fee: plan.fee,
                    specialty: specialty,
                    bio: "\(name)，\(plan.title)，从业 \(plan.years) 年。长期坐诊\(departmentSpec.name)，擅长\(specialty)。"
                )
                snapshot.doctors.append(doctor)
                doctorSerial += 1
            }
        }
    }

    assert(Set(snapshot.hospitals.map(\.id)).count == snapshot.hospitals.count)
    assert(Set(snapshot.departments.map(\.id)).count == snapshot.departments.count)
    assert(Set(snapshot.doctors.map(\.id)).count == snapshot.doctors.count)
    assert(!snapshot.hospitals.isEmpty)
    #if DEBUG
    assertSlotIDsUnique()
    #endif
    return snapshot
}

#if DEBUG
private func assertSlotIDsUnique() {
    var seen = Set<UUID>()
    let start = BookingCalendar.startOfDay(Date(timeIntervalSince1970: 1_700_000_000))
    for dayOffset in 0..<10 {
        guard let day = BookingCalendar.calendar.date(byAdding: .day, value: dayOffset, to: start) else {
            assertionFailure("无法生成测试日期")
            return
        }
        let datePart = BookingCalendar.datePart(day)
        for index in 0..<slotTemplates.count {
            let id = StableID.slotID(doctorSerial: 1, datePart: datePart, slotIndex: index)
            assert(seen.insert(id).inserted)
        }
    }
}
#endif

private let generalDepartments: [DepartmentSpec] = [
    DepartmentSpec(name: "心血管内科", symbol: "heart.fill", summary: "高血压、冠心病与心律问题", specialties: ["冠心病与心力衰竭", "高血压和血脂异常", "心律失常与晕厥"]),
    DepartmentSpec(name: "呼吸内科", symbol: "lungs.fill", summary: "咳嗽、哮喘与呼吸道感染", specialties: ["慢性咳嗽与哮喘", "肺部感染与慢阻肺", "睡眠呼吸问题"]),
    DepartmentSpec(name: "消化内科", symbol: "pills.fill", summary: "胃痛、肝胆与消化不良", specialties: ["胃食管反流与胃炎", "肝胆疾病随访", "功能性消化不良"]),
    DepartmentSpec(name: "神经内科", symbol: "brain.head.profile", summary: "头痛、头晕与脑血管病", specialties: ["头痛与眩晕", "脑血管病随访", "失眠与周围神经疾病"]),
    DepartmentSpec(name: "普通外科", symbol: "bandage.fill", summary: "甲状腺、疝气与体表肿物", specialties: ["甲状腺与乳腺疾病", "腹外疝与胆道疾病", "体表肿物评估"]),
    DepartmentSpec(name: "骨科", symbol: "figure.walk", summary: "颈肩腰腿痛与运动损伤", specialties: ["颈腰椎疾病", "关节疼痛", "运动损伤"]),
    DepartmentSpec(name: "儿科", symbol: "figure.and.child.holdinghands", summary: "儿童常见病与保健", specialties: ["儿童呼吸道感染", "消化与过敏", "生长发育咨询"]),
    DepartmentSpec(name: "眼科", symbol: "eye.fill", summary: "近视、白内障与眼表疾病", specialties: ["屈光与视疲劳", "白内障评估", "干眼与结膜炎"]),
    DepartmentSpec(name: "皮肤科", symbol: "hand.raised.fill", summary: "湿疹、痤疮与过敏", specialties: ["湿疹与皮炎", "痤疮与色斑", "荨麻疹与真菌病"]),
    DepartmentSpec(name: "耳鼻喉科", symbol: "ear.fill", summary: "鼻炎、咽喉炎与耳鸣", specialties: ["过敏性鼻炎", "咽喉与扁桃体疾病", "耳鸣与中耳炎"]),
]

private let tcmDepartments: [DepartmentSpec] = [
    DepartmentSpec(name: "中医内科", symbol: "leaf.fill", summary: "感冒、脾胃与虚劳调理", specialties: ["脾胃虚弱", "感冒与咳嗽", "失眠与疲劳"]),
    DepartmentSpec(name: "针灸科", symbol: "bolt.fill", summary: "疼痛、面瘫与中风后遗症", specialties: ["颈肩腰腿痛", "面瘫与头痛", "中风后康复"]),
    DepartmentSpec(name: "推拿科", symbol: "hand.raised.fill", summary: "筋骨不适与亚健康", specialties: ["落枕与腰肌劳损", "小儿推拿保健", "慢性劳损"]),
    DepartmentSpec(name: "中医骨伤", symbol: "figure.walk", summary: "扭挫伤与骨关节退变", specialties: ["急性扭伤", "膝骨关节炎", "腰腿痛"]),
    DepartmentSpec(name: "治未病科", symbol: "sun.max.fill", summary: "体质辨识与健康调养", specialties: ["体质辨识", "季节调养", "慢性病中医管理"]),
    DepartmentSpec(name: "康复科", symbol: "waveform.path.ecg", summary: "术后与慢病功能康复", specialties: ["术后功能锻炼", "颈腰椎康复", "平衡与步态训练"]),
]

private let maternalDepartments: [DepartmentSpec] = [
    DepartmentSpec(name: "妇科", symbol: "person.fill", summary: "月经、炎症与妇科常见病", specialties: ["月经不调", "妇科炎症", "更年期保健"]),
    DepartmentSpec(name: "产科", symbol: "stroller.fill", summary: "产检、孕期咨询与分娩评估", specialties: ["常规产检", "孕期营养咨询", "高危妊娠随访"]),
    DepartmentSpec(name: "儿科", symbol: "figure.and.child.holdinghands", summary: "儿童发热、咳嗽与保健", specialties: ["儿童发热咳嗽", "过敏与湿疹", "儿童保健"]),
    DepartmentSpec(name: "新生儿科", symbol: "heart.fill", summary: "新生儿黄疸与喂养咨询", specialties: ["新生儿黄疸", "喂养与护理", "早产儿随访"]),
    DepartmentSpec(name: "生殖医学科", symbol: "heart.text.square.fill", summary: "备孕与生育力评估", specialties: ["备孕咨询", "月经与排卵评估", "复发性流产随访"]),
    DepartmentSpec(name: "妇女保健科", symbol: "cross.case.fill", summary: "两癌筛查与日常保健", specialties: ["宫颈与乳腺筛查", "孕前保健", "盆底健康"]),
]

private let orthoDepartments: [DepartmentSpec] = [
    DepartmentSpec(name: "关节外科", symbol: "figure.walk", summary: "髋膝肩关节疼痛与置换评估", specialties: ["膝关节骨关节炎", "髋关节疼痛", "肩关节疾病"]),
    DepartmentSpec(name: "脊柱外科", symbol: "figure.stand", summary: "颈椎病、腰椎间盘突出", specialties: ["颈椎病", "腰椎间盘突出", "脊柱侧弯随访"]),
    DepartmentSpec(name: "创伤骨科", symbol: "bandage.fill", summary: "骨折、脱位与运动外伤", specialties: ["四肢骨折随访", "关节脱位", "软组织损伤"]),
    DepartmentSpec(name: "运动医学科", symbol: "figure.run", summary: "韧带、半月板与运动康复", specialties: ["膝关节运动损伤", "肩袖损伤", "运动康复"]),
    DepartmentSpec(name: "康复科", symbol: "waveform.path.ecg", summary: "术后与慢性疼痛康复", specialties: ["术后康复", "慢性疼痛", "步态训练"]),
]

private let dentalDepartments: [DepartmentSpec] = [
    DepartmentSpec(name: "口腔内科", symbol: "face.smiling.fill", summary: "龋齿、牙髓炎与牙周病", specialties: ["龋齿与牙髓炎", "牙周病", "牙齿敏感"]),
    DepartmentSpec(name: "口腔外科", symbol: "bandage.fill", summary: "阻生齿与口腔小手术评估", specialties: ["智齿冠周炎", "阻生齿评估", "口腔黏膜病"]),
    DepartmentSpec(name: "正畸科", symbol: "eyeglasses", summary: "牙齿不齐与咬合问题", specialties: ["青少年矫治咨询", "成人正畸", "咬合紊乱"]),
    DepartmentSpec(name: "种植科", symbol: "cross.case.fill", summary: "缺牙修复与种植咨询", specialties: ["单颗缺牙", "多颗缺牙修复", "种植维护"]),
    DepartmentSpec(name: "儿童口腔科", symbol: "figure.and.child.holdinghands", summary: "儿童龋齿与涂氟窝沟封闭", specialties: ["儿童龋齿", "涂氟与窝沟封闭", "替牙期咨询"]),
]

private let hospitalSpecs: [HospitalSpec] = [
    HospitalSpec(
        name: "滨安市第一人民医院",
        level: "三级甲等",
        category: .general,
        district: "江北区",
        address: "解放路 188 号",
        phone: "0574-88001188",
        openHours: "周一至周日 08:00-17:00",
        summary: "市级综合医院，覆盖内科、外科和常见专科门诊。",
        symbol: "building.2.fill",
        departments: generalDepartments
    ),
    HospitalSpec(
        name: "滨安大学附属医院",
        level: "三级甲等",
        category: .general,
        district: "学院区",
        address: "学府路 1 号",
        phone: "0574-88002001",
        openHours: "周一至周日 08:00-17:00",
        summary: "教学医院，内外妇儿重点学科均可预约普通门诊。",
        symbol: "building.columns.fill",
        departments: generalDepartments
    ),
    HospitalSpec(
        name: "滨安市中医医院",
        level: "三级甲等",
        category: .tcm,
        district: "杏林区",
        address: "杏林街 26 号",
        phone: "0574-88003026",
        openHours: "周一至周日 08:00-16:30",
        summary: "以中医内科、针灸推拿和康复调理为特色。",
        symbol: "leaf.fill",
        departments: tcmDepartments
    ),
    HospitalSpec(
        name: "滨安市妇幼保健院",
        level: "三级甲等",
        category: .maternal,
        district: "望湖区",
        address: "育婴巷 9 号",
        phone: "0574-88004009",
        openHours: "周一至周日 08:00-17:00",
        summary: "面向妇女儿童的保健与常见病门诊。",
        symbol: "figure.and.child.holdinghands",
        departments: maternalDepartments
    ),
    HospitalSpec(
        name: "滨安骨科医院",
        level: "二级甲等",
        category: .specialty,
        district: "城南区",
        address: "城南路 55 号",
        phone: "0574-88005055",
        openHours: "周一至周六 08:00-17:00",
        summary: "专注骨与关节疾病、运动损伤和术后康复。",
        symbol: "figure.walk",
        departments: orthoDepartments
    ),
    HospitalSpec(
        name: "滨安市口腔医院",
        level: "三级专科",
        category: .specialty,
        district: "文昌区",
        address: "文化路 12 号",
        phone: "0574-88006012",
        openHours: "周一至周六 08:30-17:00",
        summary: "口腔内科、外科、正畸和种植均可在线选号。",
        symbol: "face.smiling.fill",
        departments: dentalDepartments
    ),
]
