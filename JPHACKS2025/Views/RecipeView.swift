import SwiftUI

struct RecipeView: View {
    // 📌 1. スクロール先のIDを保持する状態変数
    @State private var currentScrollID = 0
    // 項目の総数
        private let itemCount = 10
    
    var body: some View {
        ScrollViewReader { proxy in
            ZStack {
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


#Preview {
    RecipeView()
}


