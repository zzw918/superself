import SwiftUI

struct TestView: View {
    @State var show = true
    var body: some View {
        Text("Test")
            .alert("Test", isPresented: $show) {
                Button("恢复到待处理") {}
                Button("取消") {}
            }
    }
}
