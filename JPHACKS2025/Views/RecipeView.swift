import SwiftUI

struct RecipeView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Color.clear
                
                Image(systemName: "globe")
                    .imageScale(.large)
                    .foregroundStyle(.tint)
                Text("Hello, recipe")
                
                Text("料理名")
                    .font(.title)
                
                ForEach(0..<10, id: \.self) { num in
                    Text("\(num)")
                        .font(.title)
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
    }
}

#Preview {
    RecipeView()
}
