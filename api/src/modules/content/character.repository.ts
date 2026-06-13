import { CharacterModel, ICharacter } from './character.model';

export class CharacterRepository {

  async findAll(filters: {
    is_active?:  boolean;
    rarity?:     string;
    is_sacred?:  boolean;
    search?:     string;
    page?:       number;
    limit?:      number;
  }): Promise<{ characters: ICharacter[]; total: number }> {
    const query: Record<string, unknown> = {};

    if (filters.is_active  !== undefined) query.is_active  = filters.is_active;
    if (filters.is_sacred  !== undefined) query.is_sacred  = filters.is_sacred;
    if (filters.rarity)                   query.rarity     = filters.rarity;
    if (filters.search) {
      query.$or = [
        { name:               { $regex: filters.search, $options: 'i' } },
        { title:              { $regex: filters.search, $options: 'i' } },
        { biblical_reference: { $regex: filters.search, $options: 'i' } },
      ];
    }

    const page  = filters.page  ?? 1;
    const limit = filters.limit ?? 50;
    const skip  = (page - 1) * limit;

    const [characters, total] = await Promise.all([
      CharacterModel.find(query)
               .populate('trail_id', 'title slug')
               .sort({ sort_order: 1, createdAt: 1 })
               .skip(skip)
               .limit(limit),
      CharacterModel.countDocuments(query),
    ]);

    return { characters, total };
  }

  async findById(id: string): Promise<ICharacter | null> {
    return CharacterModel.findById(id).populate('trail_id', 'title slug');
  }

  async findAllActive(): Promise<ICharacter[]> {
    return CharacterModel.find({ is_active: true })
                    .populate('trail_id', 'title slug')
                    .sort({ sort_order: 1 })
                    .select('-__v');
  }

  async create(data: Partial<ICharacter>): Promise<ICharacter> {
    if (data.sort_order === undefined) {
      const last = await CharacterModel.findOne().sort({ sort_order: -1 });
      data.sort_order = last ? last.sort_order + 1 : 0;
    }
    return CharacterModel.create(data);
  }

  async update(id: string, data: Partial<ICharacter>): Promise<ICharacter | null> {
    return CharacterModel.findByIdAndUpdate(
      id,
      { $set: data },
      { new: true, runValidators: true },
    ).populate('trail_id', 'title slug');
  }

  async delete(id: string): Promise<boolean> {
    const result = await CharacterModel.findByIdAndDelete(id);
    return !!result;
  }

  async toggleActive(id: string): Promise<ICharacter | null> {
    const character = await CharacterModel.findById(id);
    if (!character) return null;
    character.is_active = !character.is_active;
    return character.save();
  }

  async getStats(): Promise<{
    total: number; active: number; inactive: number;
    common: number; uncommon: number; rare: number; epic: number; special: number;
    sacred: number;
  }> {
    const result = await CharacterModel.aggregate([
      {
        $group: {
          _id:      null,
          total:    { $sum: 1 },
          active:   { $sum: { $cond: ['$is_active', 1, 0] } },
          inactive: { $sum: { $cond: [{ $not: '$is_active' }, 1, 0] } },
          common:   { $sum: { $cond: [{ $eq: ['$rarity', 'common'] },   1, 0] } },
          uncommon: { $sum: { $cond: [{ $eq: ['$rarity', 'uncommon'] }, 1, 0] } },
          rare:     { $sum: { $cond: [{ $eq: ['$rarity', 'rare'] },     1, 0] } },
          epic:     { $sum: { $cond: [{ $eq: ['$rarity', 'epic'] },     1, 0] } },
          special:  { $sum: { $cond: [{ $eq: ['$rarity', 'special'] },  1, 0] } },
          sacred:   { $sum: { $cond: ['$is_sacred', 1, 0] } },
        },
      },
    ]);

    const stats = result[0] ?? {
      total: 0, active: 0, inactive: 0,
      common: 0, uncommon: 0, rare: 0, epic: 0, special: 0, sacred: 0,
    };
    delete stats._id;
    return stats;
  }

  async seedMany(characters: Partial<ICharacter>[]): Promise<{
    created: number;
    updated: number;
    errors:  string[];
  }> {
    let created = 0;
    let updated = 0;
    const errors: string[] = [];

    for (const char of characters) {
      try {
        const existing = await CharacterModel.findOne({ name: char.name });
        if (existing) {
          await CharacterModel.findByIdAndUpdate(existing._id, { $set: char });
          updated++;
        } else {
          await CharacterModel.create(char);
          created++;
        }
      } catch (err: unknown) {
        errors.push(`Erro em "${char.name}": ${(err as Error).message}`);
      }
    }

    return { created, updated, errors };
  }
}

export const characterRepository = new CharacterRepository();
