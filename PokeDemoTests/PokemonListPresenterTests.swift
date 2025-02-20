//
//  PokeDemoTests.swift
//  PokeDemoTests
//
//  Created by Rudr Bansal on 06/08/22.
//

import XCTest
@testable import PokeDemo

final class PokemonListPresenterTests: XCTestCase {
    
    private(set) var presenter: PokemonListPresenter?
    private let mockService = MockService()
    
    // MARK: - Lifecycle
    
    override func setUp() {
        super.setUp()
        presenter = PokemonListPresenter(service: mockService)
    }
    
    override func tearDown() {
        presenter = nil
        super.tearDown()
    }
    
    // MARK: - Tests
    
    func testDelegateSetsValidValue(){
        // Given
        let mockDelegate = MockPokemonListViewPresenterDelegate()
        
        // When
        presenter?.delegate = mockDelegate
        
        // Then
        XCTAssertTrue(presenter?.delegate is MockPokemonListViewPresenterDelegate)
    }
    
    func testGetPokemonListCallsAPI(){
        
        // When
        presenter?.viewDidLoad()
        
        // Then
        XCTAssertEqual(mockService.sendRequestWithJSONIsCalledCount, 1)
        XCTAssertEqual(mockService.sendRequestWithJSONEndPoint, "https://pokeapi.co/api/v2/pokemon")
        XCTAssertEqual(mockService.sendRequestWithJSONMethod, .get)
        XCTAssertNil(mockService.sendRequestWithJSONParameter)
        XCTAssertNil(mockService.sendRequestWithJSONHeader)
    }
    
    func testGetPokemonListReturnsSuccess(){
        // Given
        let mockDelegate = MockPokemonListViewPresenterDelegate()
        presenter = PokemonListPresenter(service: mockService)
        presenter?.delegate = mockDelegate
        presenter?.viewDidLoad()
        
        // When service sends successful response
        
        let jsonData = JSONString.success.data(using: .utf8)
        mockService.onCompletion?(jsonData, nil)
        
        // Then
        XCTAssertEqual(mockService.sendRequestWithJSONIsCalledCount, 1)
        XCTAssertEqual(mockDelegate.pokemons?.first?.name, "test")
        XCTAssertEqual(mockDelegate.pokemons?.first?.url, "testURL")
    }
    
    func testGetPokemonListReturnsError(){
        // Given
        let mockDelegate = MockPokemonListViewPresenterDelegate()
        presenter = PokemonListPresenter(service: mockService)
        presenter?.delegate = mockDelegate
        presenter?.viewDidLoad()
        
        // When service sends error
        mockService.onCompletion?(nil, TestError())
        
        // Then
        XCTAssertEqual(mockService.sendRequestWithJSONIsCalledCount, 1)
        XCTAssertEqual(mockDelegate.pokemonsFetchedCount, 0)
        XCTAssertEqual(mockDelegate.showAlertCalledCount, 1)
        XCTAssertEqual(mockDelegate.showAlertTitle, "Error")
        XCTAssertEqual(mockDelegate.showAlertMessage, "The operation couldn’t be completed. (PokeDemoTests.TestError error 1.)")
    }
    
    func testGetPokemonListReturnsEmptyArray() {
        // Given
        let mockDelegate = MockPokemonListViewPresenterDelegate()
        presenter?.delegate = mockDelegate
        presenter?.viewDidLoad()
        
        // When service sends empty array in response
        let jsonData = JSONString.successWithEmptyArray.data(using: .utf8)
        mockService.onCompletion?(jsonData, nil)
        
        // Then
        XCTAssertEqual(mockService.sendRequestWithJSONIsCalledCount, 1)
        XCTAssertEqual(mockDelegate.pokemons?.count, 0)
    }
    
    func testGetPokemonListReturnsNil(){
        // Given
        let mockDelegate = MockPokemonListViewPresenterDelegate()
        presenter = PokemonListPresenter(service: mockService)
        presenter?.delegate = mockDelegate
        presenter?.viewDidLoad()
        
        // When service sends nil
        mockService.onCompletion?(nil, nil)
        
        // Then
        XCTAssertEqual(mockService.sendRequestWithJSONIsCalledCount, 1)
        XCTAssertEqual(mockDelegate.pokemonsFetchedCount, 0)
        XCTAssertEqual(mockDelegate.showAlertCalledCount, 1)
        XCTAssertEqual(mockDelegate.showAlertTitle, "Error")
        XCTAssertEqual(mockDelegate.showAlertMessage, "Sorry, something went wrong")
    }
    
    func testGetPokemonListReturnsSuccessWithError(){
        // Given
        let mockDelegate = MockPokemonListViewPresenterDelegate()
        presenter = PokemonListPresenter(service: mockService)
        presenter?.delegate = mockDelegate
        presenter?.viewDidLoad()
        
        // When service sends successful response with error
        let jsonData = JSONString.success.data(using: .utf8)
        mockService.onCompletion?(jsonData, TestError())

        // Then
        XCTAssertEqual(mockService.sendRequestWithJSONIsCalledCount, 1)
        XCTAssertEqual(mockDelegate.pokemonsFetchedCount, 0)
        XCTAssertEqual(mockDelegate.showAlertCalledCount, 1)
        XCTAssertEqual(mockDelegate.showAlertTitle, "Error")
        XCTAssertEqual(mockDelegate.showAlertMessage, "The operation couldn’t be completed. (PokeDemoTests.TestError error 1.)")
    }
    
    func testGetPokemonListReturnsWrongData(){
        // Given
        let mockDelegate = MockPokemonListViewPresenterDelegate()
        presenter = PokemonListPresenter(service: mockService)
        presenter?.delegate = mockDelegate
        presenter?.viewDidLoad()
        
        // When service sends wrong response
        let jsonData = JSONString.successWithWrongData.data(using: .utf8)
        mockService.onCompletion?(jsonData, nil)
        
        // Then
        XCTAssertEqual(mockService.sendRequestWithJSONIsCalledCount, 1)
    }
}

private extension PokemonListPresenterTests {
    enum JSONString {
        static let success = """
        {
            "count": 1279,
            "next": "https://pokeapi.co/api/v2/pokemon?offset=20&limit=20",
            "previous": null,
            "results": [{
                "name": "test",
                "url": "testURL"
            }]
        }
        """
        static let successWithEmptyArray = """
        {
            "count": 1279,
            "next": "https://pokeapi.co/api/v2/pokemon?offset=20&limit=20",
            "previous": null,
            "results": []
        }
        """
        static let successWithWrongData = """
        {
            "count": 1279,
            "next": "https://pokeapi.co/api/v2/pokemon?offset=20&limit=20",
            "previous": null,
            "results": [{
                "name": 123,
                "url": "testURL"
            }]
        }
        """
    }
}

struct TestError: Error{
    
}

final class MockPokemonListViewPresenterDelegate: PokemonListPresenterDelegate {
    
    private(set) var pokemonsFetchedCount: Int = 0
    private(set) var showAlertCalledCount: Int = 0
    private(set) var showAlertTitle: String?
    private(set) var showAlertMessage: String?
    private(set) var pokemons: [Pokemon]?
    
    func show(_ pokemons: [Pokemon]) {
        pokemonsFetchedCount += 1
        self.pokemons = pokemons
    }
    
    func showAlert(title: String, message: String) {
        showAlertCalledCount += 1
        showAlertTitle = title
        showAlertMessage = message
    }
}
