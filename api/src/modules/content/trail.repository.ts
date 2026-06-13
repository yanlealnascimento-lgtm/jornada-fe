import { TrailModel, ITrail } from './trail.model';
import mongoose from 'mongoose';

export class TrailRepository {

  async findAll(filters: {
    is_published?: boolean;
    is_core?: boolean;
    is_premium?: boolean;
    denomination?: string;
    company_id?: string;
    search?: string;
    page?: number;
    limit?: number;
  }): Promise<{ trails: ITrail[]; total: number }> {
    const query: Record<string, unknown> = {};

    if (filters.is_published !== undefined) query.is_published = filters.is_published;
    if (filters.is_core      !== undefined) query.is_core      = filters.is_core;
    if (filters.is_premium   !== undefined) query.is_premium   = filters.is_premium;
    if (filters.denomination)               query.denomination  = filters.denomination;
    if (filters.company_id)                 query.company_id   = new mongoose.Types.ObjectId(filters.company_id);
    if (filters.search) {
      query.$or = [
        { title:       { $regex: filters.search, $options: 'i' } },
        { description: { $regex: filters.search, $options: 'i' } },
      ];
    }

    const page  = filters.page  ?? 1;
    const limit = filters.limit ?? 50;
    const skip  = (page - 1) * limit;

    const [trails, total] = await Promise.all([
      TrailModel.find(query)
           .populate('character_id', 'name title sprite_url color_hex')
           .sort({ order: 1, createdAt: 1 })
           .skip(skip)
           .limit(limit),
      TrailModel.countDocuments(query),
    ]);

    return { trails, total };
  }

  async findById(id: string): Promise<ITrail | null> {
    return TrailModel.findById(id).populate('character_id', 'name title sprite_url color_hex');
  }

  async findBySlug(slug: string): Promise<ITrail | null> {
    return TrailModel.findOne({ slug }).populate('character_id', 'name title sprite_url color_hex');
  }

  async create(data: Partial<ITrail>): Promise<ITrail> {
    if (data.order === undefined) {
      const last = await TrailModel.findOne().sort({ order: -1 });
      data.order = last ? last.order + 1 : 0;
    }
    return TrailModel.create(data);
  }

  async update(id: string, data: Partial<ITrail>): Promise<ITrail | null> {
    return TrailModel.findByIdAndUpdate(id, { $set: data }, { new: true, runValidators: true })
                .populate('character_id', 'name title sprite_url color_hex');
  }

  async delete(id: string): Promise<boolean> {
    const result = await TrailModel.findByIdAndDelete(id);
    return !!result;
  }

  async reorder(items: { id: string; order: number }[]): Promise<void> {
    const ops = items.map(({ id, order }) => ({
      updateOne: {
        filter: { _id: new mongoose.Types.ObjectId(id) },
        update: { $set: { order } },
      },
    }));
    await TrailModel.bulkWrite(ops);
  }

  async getStats(): Promise<{
    total: number;
    published: number;
    draft: number;
    free: number;
    premium: number;
    core: number;
    denomination: number;
    by_denomination: Record<string, number>;
  }> {
    const [counts, byDenomination] = await Promise.all([
      TrailModel.aggregate([
        {
          $group: {
            _id: null,
            total:       { $sum: 1 },
            published:   { $sum: { $cond: ['$is_published', 1, 0] } },
            draft:       { $sum: { $cond: [{ $not: '$is_published' }, 1, 0] } },
            free:        { $sum: { $cond: [{ $not: '$is_premium' }, 1, 0] } },
            premium:     { $sum: { $cond: ['$is_premium', 1, 0] } },
            core:        { $sum: { $cond: ['$is_core', 1, 0] } },
            denomination:{ $sum: { $cond: [{ $not: '$is_core' }, 1, 0] } },
          },
        },
      ]),
      TrailModel.aggregate([
        { $match:  { is_core: false, denomination: { $exists: true } } },
        { $group:  { _id: '$denomination', count: { $sum: 1 } } },
        { $sort:   { count: -1 } },
      ]),
    ]);

    const stats = counts[0] ?? {
      total: 0, published: 0, draft: 0,
      free: 0, premium: 0, core: 0, denomination: 0,
    };
    delete stats._id;

    const by_denomination: Record<string, number> = {};
    byDenomination.forEach((d: { _id: string; count: number }) => {
      by_denomination[d._id] = d.count;
    });

    return { ...stats, by_denomination };
  }

  async seedMany(trails: Partial<ITrail>[]): Promise<{
    created: number;
    updated: number;
    errors:  string[];
  }> {
    let created = 0;
    let updated = 0;
    const errors: string[] = [];

    for (const trail of trails) {
      try {
        const result = await TrailModel.findOneAndUpdate(
          { slug: trail.slug },
          { $set: trail },
          { upsert: true, new: true, setDefaultsOnInsert: true },
        );
        if (result.createdAt.getTime() === result.updatedAt.getTime()) {
          created++;
        } else {
          updated++;
        }
      } catch (err: unknown) {
        errors.push(`Erro em "${trail.title}": ${(err as Error).message}`);
      }
    }

    return { created, updated, errors };
  }
}

export const trailRepository = new TrailRepository();
