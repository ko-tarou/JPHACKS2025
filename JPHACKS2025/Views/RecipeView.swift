import SwiftUI
import Vision
import VisionKit

struct RecipeView: View {
    // 📌 1. スクロール先のIDを保持する状態変数
    @State private var currentScrollID = 0
    // 項目の総数
        private let itemCount = 10
    
    private let isEyesOk = false
    
    var body: some View {
        ScrollViewReader { proxy in
            ZStack {
                VStack {
                    Text(isEyesOk ? "OK👀" : "NO")
                        .font(.title)
                        .padding()
                        .frame(width: 200, height: 100)
                        .background(Color.gray.opacity(0.3))
                    
                    
                    Spacer()
                }
                
                
                ScrollView {
                    VStack(alignment: .leading) {
                        Color.clear
                        
                        Image(systemName: "globe")
                            .imageScale(.large)
                            .foregroundStyle(.tint)
                        Text("Hello, recipe")
                        
                        Text("料理名")
                            .font(.title)
                        
                        ForEach(0..<itemCount, id: \.self) { num in
                            
                            Text("\(num)")
                                .font(.title)
                                .id(num)
                            
                            Text("""
                                hogehoge
                                hogehoge
                                hogehoge
                                hogehoge
                                """)
                                .padding(10)
                                .font(.title)
                        }
                    }
                    .padding()
                    .frame(width: .infinity)
                }
                
                
                HStack{
                    Spacer()
                    
                    VStack{
                        // 上ボタン
                        Button {
                            guard 0 < currentScrollID else { return }
                            currentScrollID -= 1
                            
                            withAnimation { // スムーズにスクロールさせる
                                proxy.scrollTo(currentScrollID, anchor: .top)
                            }
                        } label: {
                            Image(systemName: "arrowshape.up.fill")
                                .padding()
                        }
                        .font(.system(size: 60))
                        .buttonStyle(.borderedProminent)
                        
                        // 下ボタン
                        Button {
                            guard currentScrollID < itemCount-3 else { return }
                            currentScrollID += 1
                            
                            withAnimation { // スムーズにスクロールさせる
                                proxy.scrollTo(currentScrollID, anchor: .top)
                            }
                        } label: {
                            Image(systemName: "arrowshape.down.fill")
                                .padding()
                        }
                        .font(.system(size: 60))
                        .buttonStyle(.borderedProminent)
                    }
                }

            }
        }
    }
}

// 顔認識してるかのカード
struct faceCard: View {
    @State var isEyesOk: Bool
    @State var isHandsfreeOk: Bool
    
    var body: some View {
        VStack{
            Text(isEyesOk ? "OK👀" : "NO")
                .font(.title)
                .padding()
                .frame(width: 200, height: 100)
                .background(Color.gray.opacity(0.3))
            
            Button {
                self.isHandsfreeOk.toggle()
            } label: {
                Text(isHandsfreeOk ? "ハンズフリーモードをOFFにする" : "ハンズフリーモードをONにする")
            }
        }
    }
}

#Preview {
    RecipeView()
}

#Preview {
    faceCard(isEyesOk: false, isHandsfreeOk: false)
}


