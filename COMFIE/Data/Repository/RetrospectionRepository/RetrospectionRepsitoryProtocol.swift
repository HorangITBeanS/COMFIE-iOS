//
//  RetrospectionRepsitoryProtocol.swift
//  COMFIE
//
//  Created by Seoyeon Choi on 4/13/25.
//

protocol RetrospectionRepsitoryProtocol {
    func save(memo: Memo) -> Result<Void, Error>
    func delete(memo: Memo) -> Result<Void, Error>
}
