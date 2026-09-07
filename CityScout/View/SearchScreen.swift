//
//  SearchScreen.swift
//  CityScout
//
//  Created by Ankur Kothawade on 06/09/26.
//

import SwiftUI


struct SearchScreen: View {
    @StateObject private var viewModel: SearchViewModel
    @FocusState private var isSearchFieldFocused: Bool

    init(viewModel: SearchViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                background

                ScrollView {
                    VStack(spacing: UIValues.Search.stackSpacing) {
                        titleHeader
                            .padding(.top, UIValues.Search.titleTopPadding)

                        searchBar
                        stateView
                    }
                    .padding(.horizontal, UIValues.Search.horizontalPadding)
                    .padding(.bottom, UIValues.Search.bottomPadding)
                }
                .scrollIndicators(.hidden)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                isSearchFieldFocused = false
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(UIStrings.App.title)
                        .font(.system(size: UIValues.Search.toolbarTitleSize, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.textPrimary)
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .background(AppColors.blackBase)
            .navigationDestination(for: City.self) { city in
                DestinationScreen(viewModel: AppSetupBuilder.makeDestinationViewModel(for: city))
            }
        }
        .preferredColorScheme(.dark)
        .onDisappear {
            viewModel.onDisappear()
        }
    }

    private var background: some View {
        ZStack {
            AppColors.deepNavy
                .ignoresSafeArea()

            LinearGradient(
                colors: [AppColors.oceanTop, AppColors.oceanMid, AppColors.oceanBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(AppColors.glow)
                .frame(width: 320, height: 320)
                .blur(radius: 18)
                .offset(x: -130, y: -300)

            Circle()
                .fill(AppColors.glow)
                .frame(width: 360, height: 360)
                .blur(radius: 20)
                .offset(x: 140, y: 250)
        }
    }

    private var titleHeader: some View {
        VStack(spacing: UIValues.Search.titleSpacing) {
            Text(UIStrings.Search.heroTitle)
                .font(.system(size: UIValues.Search.titleSize, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.textPrimary)
                .multilineTextAlignment(.center)

            Text(UIStrings.Search.heroSubtitle)
                .font(.system(size: UIValues.Search.subtitleSize, weight: .medium, design: .rounded))
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private var searchBar: some View {
        HStack(spacing: UIValues.Search.searchBarSpacing) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(AppColors.iconMuted)

            TextField(
                "",
                text: $viewModel.query,
                prompt: Text(UIStrings.Search.searchPrompt).foregroundStyle(AppColors.placeholder)
            )
                .focused($isSearchFieldFocused)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .foregroundStyle(AppColors.textPrimary)
                .submitLabel(.search)
                .onSubmit {
                    viewModel.search()
                }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            isSearchFieldFocused = true
        }
        .padding(UIValues.Search.searchBarPadding)
        .background(
            RoundedRectangle(cornerRadius: UIValues.Search.cardCornerRadius, style: .continuous)
                .fill(AppColors.searchBarFill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: UIValues.Search.cardCornerRadius, style: .continuous)
                .stroke(AppColors.searchBarStroke, lineWidth: UIValues.Search.cardStroke)
        )
    }

    @ViewBuilder
    private var stateView: some View {
        switch viewModel.state {
        case .idle:
            readyHintCard

        case .searching:
            cardContainer {
                HStack(spacing: UIValues.Search.titleSpacing * 3) {
                    ProgressView()
                        .tint(AppColors.textPrimary)
                    Text(UIStrings.Search.searchingMessage)
                        .font(.system(size: UIValues.Search.searchingSize, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppColors.textPrimary)
                }
            }

        case let .results(cities):
            if cities.isEmpty {
                cardContainer {
                    Text(UIStrings.Search.noResultsMessage)
                        .foregroundStyle(AppColors.textElevated)
                }
            } else {
                VStack(spacing: UIValues.Search.listSpacing) {
                    ForEach(cities) { city in
                        NavigationLink(value: city) {
                            cityRow(city)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

        case let .failed(message):
            cardContainer {
                Text(message)
                    .foregroundStyle(AppColors.textPrimary)
                    .font(.system(size: UIValues.Search.infoBodySize, weight: .semibold, design: .rounded))
            }
        }
    }

    private var readyHintCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppColors.iconMuted)

                Text(UIStrings.Search.readyTitle)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppColors.textElevated)
            }

            Text(UIStrings.Search.readySubtitle)
                .font(.system(size: UIValues.Search.infoBodySize, weight: .medium, design: .rounded))
                .foregroundStyle(AppColors.textMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(UIValues.Search.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: UIValues.Search.cardCornerRadius, style: .continuous)
                .fill(AppColors.readyFill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: UIValues.Search.cardCornerRadius, style: .continuous)
                .stroke(style: StrokeStyle(lineWidth: 1, dash: [6, 6]))
                .foregroundStyle(AppColors.readyStroke)
        )
    }

    private func cardContainer<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        content()
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(UIValues.Search.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: UIValues.Search.cardCornerRadius, style: .continuous)
                    .fill(AppColors.cardFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: UIValues.Search.cardCornerRadius, style: .continuous)
                    .stroke(AppColors.cardStroke, lineWidth: UIValues.Search.cardStroke)
            )
    }

    private func cityRow(_ city: City) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: UIValues.Search.rowSpacing) {
                Text(city.name)
                    .font(.system(size: UIValues.Search.rowTitleSize, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.textPrimary)
                Text(city.country)
                    .font(.system(size: UIValues.Search.rowSubtitleSize, weight: .medium, design: .rounded))
                    .foregroundStyle(AppColors.textSecondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(AppColors.iconMuted)
        }
        .padding(UIValues.Search.rowPadding)
        .background(
            RoundedRectangle(cornerRadius: UIValues.Search.rowCornerRadius, style: .continuous)
                .fill(AppColors.rowFill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: UIValues.Search.rowCornerRadius, style: .continuous)
                .stroke(AppColors.cardStroke, lineWidth: UIValues.Search.cardStroke)
        )
    }
}

#Preview {
    SearchScreen(viewModel: AppSetupBuilder.makePreviewSearchViewModel())
}
