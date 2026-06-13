import { trailRepository } from './trail.repository';
import { generateSlug } from './trail.validator';
import { SEED_TRAILS } from '../../config/seeds/trail.seed';
import mongoose from 'mongoose';
import type { CreateTrailInput, UpdateTrailInput, ReorderTrailInput } from './trail.validator';

function toTrailData(input: Record<string, unknown>): Record<string, unknown> {
  const data = { ...input };
  if (data.character_id && typeof data.character_id === 'string') {
    data.character_id = new mongoose.Types.ObjectId(data.character_id as string);
  }
  if (data.company_id && typeof data.company_id === 'string') {
    data.company_id = new mongoose.Types.ObjectId(data.company_id as string);
  }
  return data;
}

export class TrailService {

  async listTrails(filters: {
    is_published?: boolean;
    is_core?: boolean;
    is_premium?: boolean;
    denomination?: string;
    company_id?: string;
    search?: string;
    page?: number;
    limit?: number;
  }) {
    return trailRepository.findAll(filters);
  }

  async listPublishedTrails(options?: { company_id?: string }) {
    return trailRepository.findAll({
      is_published: true,
      ...options,
    });
  }

  async getTrailById(id: string) {
    const trail = await trailRepository.findById(id);
    if (!trail) throw new Error('TRAIL_NOT_FOUND');
    return trail;
  }

  async getTrailBySlug(slug: string) {
    const trail = await trailRepository.findBySlug(slug);
    if (!trail) throw new Error('TRAIL_NOT_FOUND');
    return trail;
  }

  async createTrail(input: CreateTrailInput) {
    const slug = input.slug?.trim()
      ? input.slug.trim()
      : generateSlug(input.title);

    const existing = await trailRepository.findBySlug(slug);
    if (existing) throw new Error('SLUG_ALREADY_EXISTS');

    return trailRepository.create(toTrailData({ ...input, slug }) as any);
  }

  async updateTrail(id: string, input: UpdateTrailInput) {
    if (input.title && !input.slug) {
      input.slug = generateSlug(input.title);
      const existing = await trailRepository.findBySlug(input.slug);
      if (existing && existing._id.toString() !== id) {
        input.slug = `${input.slug}-${Date.now()}`;
      }
    }

    const trail = await trailRepository.update(id, toTrailData(input as any) as any);
    if (!trail) throw new Error('TRAIL_NOT_FOUND');
    return trail;
  }

  async deleteTrail(id: string) {
    const deleted = await trailRepository.delete(id);
    if (!deleted) throw new Error('TRAIL_NOT_FOUND');
    return { deleted: true };
  }

  async reorderTrails(input: ReorderTrailInput) {
    await trailRepository.reorder(input.items);
    return { reordered: input.items.length };
  }

  async getStats() {
    return trailRepository.getStats();
  }

  async runSeed() {
    return trailRepository.seedMany(SEED_TRAILS);
  }
}

export const trailService = new TrailService();
