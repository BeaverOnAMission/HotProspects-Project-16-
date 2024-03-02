//
//  ProspectView.swift
//  HotProspects(Project 16)
//
//  Created by mac on 26.08.2023.
//
import CodeScanner
import SwiftUI
import UserNotifications

struct ProspectView: View {
    enum FilterType {
        case none, contacted, uncontacted
    }
    enum SortType {
        case name, date
    }
    @Environment(\.editMode) private var editMode
    @EnvironmentObject var prospects: Prospects
    let filter: FilterType
    @State private var isShowingScanner = false
    @State private var sortOrder = SortType.date
    @State private var isShowingSortOptions = false
    
    var body: some View {
        NavigationView{
            List {
                ForEach(filteredProspects) { prospect in
                    HStack{
                        VStack(alignment: .leading){
                            Text(prospect.name)
                                .font(.headline)
                            Text(prospect.emailAddress)
                                .foregroundColor(.secondary)
                        }
                        if prospect.isContacted{
                            Spacer()
                            Image(systemName: "tag.fill").foregroundColor(.green)
                        }
                    }
                    .swipeActions{
                        if (editMode != nil){
                            
                        }
                        else if prospect.isContacted {
                            Button{
                                prospects.toggle(prospect)
                            } label: {
                                Label("Mark UNcontacted", systemImage: "person.crop.circle.badge.xmark")
                            }.tint(.red)
                        }
                        else {
                            Button{
                                prospects.toggle(prospect)
                            } label: {
                                Label("Mark Contacted", systemImage: "person.crop.circle.fill.badge.checkmark")
                            }
                            .tint(.green)
                            
                            Button {
                                addNotification(for: prospect)
                            } label: {
                                Label("Remind me", systemImage: "bell")
                            }.tint(.orange)
                        }
                    }
                }
                .onDelete(perform: prospects.delete)
                Text("People: \(filteredProspects.count)")

            }
                .navigationTitle(title)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            EditButton()
                            
                        }

                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button {
                                isShowingSortOptions = true
                            } label: {
                                Label("Sort", systemImage: "arrow.up.arrow.down")
                            }
                        }
                        
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button {
                                isShowingScanner = true
                            } label: {
                                Label("Scan", systemImage: "qrcode.viewfinder")
                            }
                        }
                    }
                .confirmationDialog("Sort by…", isPresented: $isShowingSortOptions) {
                    Button("Name (A-Z)") { sortOrder = .name }
                    Button("Date (Newest first)") { sortOrder = .date }
                }
                .sheet(isPresented: $isShowingScanner){
                    CodeScannerView(codeTypes: [.qr], simulatedData: "PaulHudson\npaul@hackingwithswift.com", completion: handleScan)
                }
        }
    }
    var title: String{
        switch filter{
        case.none:
            return "everyone"
        case.contacted:
            return "contacted"
        case.uncontacted:
            return "uncontacted"
        }
    }
    var filteredProspects: [Prospect] {
        let result: [Prospect]

        switch filter {
        case .none:
            result = prospects.people
        case .contacted:
            result = prospects.people.filter { $0.isContacted }
        case .uncontacted:
            result = prospects.people.filter { !$0.isContacted }
        }

        if sortOrder == .name {
            return result.sorted { $0.name < $1.name }
        } else {
            return result.reversed()
        }
    }
    func handleScan(result: Result<ScanResult, ScanError>) {
        isShowingScanner = false
        switch result {
        case .success(let result):
            let details = result.string.components(separatedBy:"\n")
            guard details.count == 2
            else {return}
            
            let person = Prospect()
            person.name = details[0]
            person.emailAddress = details[1]
            prospects.add(person )
        case .failure(let error):
            print("Scanning failed: \(error.localizedDescription)")
        }
    }
    
    func addNotification(for prospect: Prospect) {
        let center = UNUserNotificationCenter.current()
        
        let addRequest = {
            let content = UNMutableNotificationContent()
            content.title = "Contact \(prospect.name)"
            content.subtitle = prospect.emailAddress
            content.sound = UNNotificationSound.default
            
            var dateCompoments = DateComponents()
            dateCompoments.hour = 9
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateCompoments, repeats: false)
            
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
            center.add(request)
        }
        
        center.getNotificationSettings { settings in
            if settings.authorizationStatus == .authorized {
                addRequest()
            } else{
                center.requestAuthorization(options: [.alert, .badge, .sound]) {success, error in
                    if success {
                        addRequest()
                    } else {
                        print(";(")
                    }
                }
            }
                
        }
        
    }
    
}

struct ProspectView_Previews: PreviewProvider {
    static var previews: some View {
        ProspectView(filter: .none).environmentObject(Prospects())
    }
}
