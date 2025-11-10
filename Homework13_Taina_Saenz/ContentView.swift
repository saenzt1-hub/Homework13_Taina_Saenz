// Taina Saenz
// Homework 13
// November 11, 2025

import SwiftUI
import Combine

// Card struct for each card in the game
struct Card: Identifiable {
    let id = UUID()
    let imageName: String
    var isFaceUp: Bool = false
    var isMatched: Bool = false
}

struct MemoryGame {
    private(set) var cards: [Card]
    private(set) var selectedCards: [Int] = []
    
    var progress: Double {
        let totalPairs = cards.count / 2
        let matchedPairs = cards.filter { $0.isMatched }.count / 2
        return totalPairs > 0 ? Double(matchedPairs) / Double(totalPairs) : 0.0
    }
    
    init(cardContents: [String]) {
        cards = []
        for content in cardContents {
            cards.append(Card(imageName: content))
            cards.append(Card(imageName: content))
        }
        cards.shuffle()
    }
    
    mutating func choose(at index: Int) {
        if cards[index].isMatched || cards[index].isFaceUp {
            return
        }
        
        cards[index].isFaceUp = true
        selectedCards.append(index)
        
        if selectedCards.count == 2 {
            let index1 = selectedCards[0]
            let index2 = selectedCards[1]
            
            if cards[index1].imageName == cards[index2].imageName {
                cards[index1].isMatched = true
                cards[index2].isMatched = true
                selectedCards = []
            }
        } else if selectedCards.count > 2 {
            let oldestIndex = selectedCards.removeFirst()
            cards[oldestIndex].isFaceUp = false
        }
    }
    
    mutating func flipBackNonMatches() {
        if selectedCards.count == 2 {
            let index1 = selectedCards[0]
            let index2 = selectedCards[1]
            
            
            if !cards[index1].isMatched && !cards[index2].isMatched {
                cards[index1].isFaceUp = false
                cards[index2].isFaceUp = false
            }
            selectedCards = []
        }
    }
}

class MemoryGameViewModel: ObservableObject {
    @Published private var model: MemoryGame
    
    private let flowers = ["flower1", "flower2","flower3", "flower4", "flower5", "flower6", "flower7", "flower8", "flower9","flower10", "flower11", "flower12"]
    
    init() {
        model = MemoryGame(cardContents: Array(flowers.prefix(6)))
    }
    
    var cards: [Card] {
        model.cards
    }
    
    var progress: Double {
        model.progress
    }
    
    func choose(card: Card) {
        if let index = model.cards.firstIndex(where: { $0.id == card.id }) {
            model.choose(at: index)
            
            if model.selectedCards.count == 2 {
                let index1 = model.selectedCards[0]
                let index2 = model.selectedCards[1]
                
                if model.cards[index1].imageName != model.cards[index2].imageName {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                        withAnimation(Animation.easeOut(duration: 0.2)) {
                            self.model.flipBackNonMatches()
                            
                        }
                    }
                }
            }
        }
    }
    func newGame() {
        model = MemoryGame(cardContents: Array(flowers.prefix(6)))
    }
}


// Main view/game layout which includes the grid and title
struct ContentView: View {
    @StateObject private var viewModel = MemoryGameViewModel()
    
    // Flower image names
    
    
    // columns for grid/layout
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    
    var body: some View {
        ZStack {
            // Game Title
            VStack {
                Text("Game")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.blue)
                    .padding(.top, 20)
                
                VStack(spacing: 8) {
                    HStack {
                        Text("Progress")
                            .font(.headline)
                            .foregroundColor(.blue)
                    }
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .frame(width: geometry.size.width, height: geometry.size.height)
                                .opacity(0.3)
                                .foregroundColor(.blue)
                            
                            Rectangle()
                                .frame(width: min(CGFloat(viewModel.progress) * geometry.size.width, geometry.size.width), height: geometry.size.height)
                                .foregroundColor(.blue)
                                .animation(.linear(duration: 0.3), value: viewModel.progress)
                        }
                        .cornerRadius(10.0)
                    }
                    .frame(height: 20)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 10)
                
                // Grid of cards, able to scroll through
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 15) {
                        ForEach(viewModel.cards) { card in
                            CardView(card: card)
                                .aspectRatio(0.75, contentMode: .fit)
                                .onTapGesture {
                                    // Add animation for the flip effect
                                    withAnimation(.easeIn(duration:0.2)){
                                        viewModel.choose(card: card)
                                    }
                                }
                                .rotation3DEffect(.degrees(card.isFaceUp ? 0 : 180), axis: (x: 0, y: 1, z: 0))
                                .opacity(card.isMatched ? 0.3 : 1) // Fade matched cards
                        }
                    }
                    .padding()
                }
                
                // Add a button to reset the game
                Button("New Game") {
                    viewModel.newGame()
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .clipShape(Capsule())
                .padding(.bottom, 20)
            }
        }
    }
}
    
    
    
    // CardView to show flower images
    struct CardView: View {
        let card: Card
        
        var body: some View {
            ZStack {
                let shape = RoundedRectangle(cornerRadius: 12)
                
                if card.isFaceUp || card.isMatched {
                    // Face up state: show the image content
                    shape
                        .fill(Color.white)
                    shape
                        .stroke(card.isMatched ? Color.green : Color.blue, lineWidth: 3)
                    
                    Image(card.imageName) // Display the content
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(5)
                    
                } else {
                    // Face down state: show the card back (blue rectangle)
                    shape
                        .fill(Color.blue)
                }
            }
        }
    }


#Preview {
    ContentView()
}

