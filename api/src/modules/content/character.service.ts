import { characterRepository } from './character.repository';
import { SEED_CHARACTERS }     from '../../config/seeds/character.seed';
import type { CreateCharacterInput, UpdateCharacterInput } from './character.validator';

export class CharacterService {

  async listActiveCharacters() {
    return characterRepository.findAllActive();
  }

  async listCharacters(filters: {
    is_active?: boolean;
    rarity?:    string;
    is_sacred?: boolean;
    search?:    string;
    page?:      number;
    limit?:     number;
  }) {
    return characterRepository.findAll(filters);
  }

  async getCharacterById(id: string) {
    const character = await characterRepository.findById(id);
    if (!character) throw new Error('CHARACTER_NOT_FOUND');
    return character;
  }

  async createCharacter(input: CreateCharacterInput) {
    if (input.is_sacred) {
      console.info(`[CharacterService] Criando personagem sagrado: ${input.name}`);
    }
    return characterRepository.create(input as any);
  }

  async updateCharacter(id: string, input: UpdateCharacterInput) {
    const character = await characterRepository.update(id, input as any);
    if (!character) throw new Error('CHARACTER_NOT_FOUND');
    return character;
  }

  async deleteCharacter(id: string) {
    const character = await characterRepository.findById(id);
    if (!character) throw new Error('CHARACTER_NOT_FOUND');
    if (character.is_sacred) throw new Error('CANNOT_DELETE_SACRED');

    const deleted = await characterRepository.delete(id);
    if (!deleted) throw new Error('CHARACTER_NOT_FOUND');
    return { deleted: true };
  }

  async toggleActive(id: string) {
    const character = await characterRepository.toggleActive(id);
    if (!character) throw new Error('CHARACTER_NOT_FOUND');
    return character;
  }

  async getStats() {
    return characterRepository.getStats();
  }

  async runSeed() {
    return characterRepository.seedMany(SEED_CHARACTERS as any[]);
  }
}

export const characterService = new CharacterService();
