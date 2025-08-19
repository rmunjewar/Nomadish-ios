import SwiftUI

struct WelcomeView: View {
    @Binding var hasSeenWelcome: Bool
    @State private var currentPage = 0
    
    private let welcomePages = [
        WelcomePage(
            title: "Welcome to Nomadish",
            subtitle: "Your Personal Food Journey Map",
            description: "Pin your favorite food memories on a map and relive those delicious moments. Share your culinary adventures with friends and discover new places to eat.",
            imageName: "map.fill",
            color: .blue
        ),
        WelcomePage(
            title: "AI-Powered Food Recognition",
            subtitle: "Smart Dish Identification",
            description: "Simply take a photo of your meal and our AI will automatically identify what you're eating. No more manual typing!",
            imageName: "camera.fill",
            color: .purple
        ),
        WelcomePage(
            title: "Share & Discover",
            subtitle: "Connect with Food Lovers",
            description: "Follow friends to see their food trails, discover new restaurants, and get inspired by their culinary adventures.",
            imageName: "heart.fill",
            color: .red
        ),
        WelcomePage(
            title: "Ready to Start?",
            subtitle: "Begin Your Food Journey",
            description: "Tap anywhere on the map to add your first food memory. Let's start mapping your delicious adventures!",
            imageName: "fork.knife",
            color: .orange
        )
    ]
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Page content
                TabView(selection: $currentPage) {
                    ForEach(0..<welcomePages.count, id: \.self) { index in
                        WelcomePageView(page: welcomePages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)
                
                // Bottom controls
                VStack(spacing: 20) {
                    // Page indicators
                    HStack(spacing: 8) {
                        ForEach(0..<welcomePages.count, id: \.self) { index in
                            Circle()
                                .fill(currentPage == index ? Color.blue : Color.gray.opacity(0.3))
                                .frame(width: 8, height: 8)
                                .animation(.easeInOut, value: currentPage)
                        }
                    }
                    
                    // Navigation buttons
                    HStack(spacing: 16) {
                        if currentPage > 0 {
                            Button("Previous") {
                                withAnimation {
                                    currentPage -= 1
                                }
                            }
                            .foregroundColor(.blue)
                        }
                        
                        Spacer()
                        
                        if currentPage < welcomePages.count - 1 {
                            Button("Next") {
                                withAnimation {
                                    currentPage += 1
                                }
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .cornerRadius(25)
                        } else {
                            Button("Get Started") {
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    hasSeenWelcome = true
                                }
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 16)
                            .background(Color.blue)
                            .cornerRadius(25)
                            .font(.headline)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 40)
            }
        }
    }
}

struct WelcomePage {
    let title: String
    let subtitle: String
    let description: String
    let imageName: String
    let color: Color
}

struct WelcomePageView: View {
    let page: WelcomePage
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Icon
            Image(systemName: page.imageName)
                .font(.system(size: 80))
                .foregroundColor(page.color)
                .padding(.bottom, 20)
            
            // Text content
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text(page.subtitle)
                    .font(.title2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Text(page.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
    }
}

#Preview {
    WelcomeView(hasSeenWelcome: .constant(false))
}
